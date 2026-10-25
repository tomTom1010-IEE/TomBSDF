"""Fail-closed Unity 2019 D3D11 bundle/zipmod audit. Does not compile or edit assets."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile
import xml.etree.ElementTree as ET

MODERN = {"tom/" + s for s in ("BSDF", "BSDFCutout", "BSDFAlpha", "BSDFAlphaBackFront", "BSDFGlass", "BSDFTess", "BSDFCutoutTess")}
BUNDLE_ENTRY = "abdata/chara/tom/shaders/tombsdf.unity3d"
STAGES = {"Fragment": 0, "Vertex": 1, "Geometry": 2, "Hull": 3, "Domain": 4}


def sha256(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def save(path, report):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")


def instruction_records(code):
    # DirectX tokenized format, not an opcode/operand semantic validator:
    # microsoft/DirectXShaderCompiler include/dxc/Support/d3d12TokenizedProgramFormat.hpp
    words = struct.unpack("<" + "I" * (len(code) // 4), code)
    cursor, records = 2, 0
    if words[1] != len(words) or len(words) <= 2:
        raise ValueError("Missing executable instruction records")
    while cursor < len(words):
        opcode = words[cursor] & 0x7ff
        if opcode == 53:  # CUSTOMDATA carries its length in the following DWORD.
            if cursor + 1 >= len(words):
                raise ValueError("Truncated custom-data length")
            length = words[cursor + 1]
            if length < 2:
                raise ValueError("Invalid custom-data length")
        else:
            length = (words[cursor] >> 24) & 0x7f
            if not length:
                raise ValueError("Zero-length instruction")
            extension = cursor
            while words[extension] & 0x80000000:
                extension += 1
                if extension >= cursor + length or extension >= len(words):
                    raise ValueError("Truncated opcode extension")
        if cursor + length > len(words):
            raise ValueError("Instruction extends beyond executable chunk")
        cursor += length
        records += 1
    return records


def dxbc(body, stage):
    """Validate container bounds, chunk offsets and the executable's SM5 stage."""
    start = body.find(b"DXBC")
    if start < 0 or len(body) - start < 32:
        raise ValueError("Missing DXBC header")
    size, count = struct.unpack_from("<II", body, start + 24)
    if not 1 <= count <= 256 or size < 32 + 4 * count or start + size > len(body):
        raise ValueError("Invalid DXBC size/chunk table")
    data = body[start:start + size]
    chunks, intervals, executable, records = [], [], False, 0
    for index in range(count):
        offset = struct.unpack_from("<I", data, 32 + index * 4)[0]
        if offset < 32 + count * 4 or offset + 8 > size:
            raise ValueError("DXBC chunk offset out of bounds")
        length = struct.unpack_from("<I", data, offset + 4)[0]
        end = offset + 8 + length
        if end > size or any(offset < b and end > a for a, b in intervals):
            raise ValueError("DXBC truncated/overlapping chunk")
        intervals.append((offset, end))
        tag = data[offset:offset + 4]
        chunks.append(tag.decode("ascii"))
        if tag in (b"SHDR", b"SHEX"):
            if length < 8 or length % 4:
                raise ValueError("Invalid shader instruction chunk")
            version, words = struct.unpack_from("<II", data, offset + 8)
            if version >> 16 != STAGES[stage] or words * 4 != length:
                raise ValueError("Wrong shader stage or instruction length")
            records += instruction_records(data[offset + 8:end])
            executable = True
    if not executable:
        raise ValueError("DXBC has no executable shader chunk")
    return {"bytes": size, "sha256": hashlib.sha256(data).hexdigest(), "chunks": chunks,
            "instructionRecords": records}


def submitted(path):
    expected, metadata = {}, []
    for line in Path(path).read_text(encoding="utf-8-sig").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        key = (row["shader"], row["pass"], row["stage"])
        variants = row.get("submitted")
        if variants is None:
            variants = []
            for variant in row["variants"]:
                platform, tier, keywords = variant.split(":", 2)
                variants.append(dict(platform=platform, tier=tier, keywords=keywords.split(),
                                     defines=row.get("platformDefinitions", [])))
        for variant in variants:
            if variant["platform"] != "D3D":
                raise ValueError("This auditor only certifies D3D11: " + variant["platform"])
            expected.setdefault(key, set()).add(tuple(sorted(variant["keywords"])))
        metadata.append(row)
    if not expected or not MODERN.issubset({k[0] for k in expected}):
        raise ValueError("Submission list is empty or omits a modern delivery shader")
    return expected, metadata


def submission_signature(metadata, shader_filter=None):
    result = set()
    for row in metadata:
        if shader_filter is not None and row["shader"] not in shader_filter:
            continue
        variants = row.get("submitted")
        if variants is None:
            definitions = row.get("platformDefinitions", [])
            if len(definitions) != 1:
                raise ValueError("Legacy capture cannot correlate multiple platform-definition sets")
            variants = []
            for value in row["variants"]:
                platform, tier, keywords = value.split(":", 2)
                variants.append(dict(platform=platform, tier=tier, keywords=keywords.split(), defines=definitions[0].split()))
        for variant in variants:
            result.add((row["shader"], row["pass"], row["stage"], variant["platform"], variant["tier"],
                        tuple(sorted(variant["keywords"])), tuple(sorted(variant["defines"]))))
    return result


def submitted_programs(metadata):
    result = {}
    for shader, pass_name, stage, platform, tier, keywords, _ in submission_signature(metadata):
        if platform != "D3D" or tier not in ("Tier1", "Tier2", "Tier3"):
            raise ValueError("Unsupported native submission platform/tier")
        result.setdefault((shader, pass_name, stage), set()).add((int(tier[-1]) - 1, keywords))
    return result


def expand_common_tier(actual, wanted):
    # Unity serializes tier-independent programs as tier 3 (not GraphicsTier.Tier3=2).
    result = set()
    for tier, keywords in actual:
        matches = {(t, k) for t, k in wanted if k == keywords}
        result.update(matches if tier == 3 and matches else {(tier, keywords)})
    return result


def audit_bundle(bundle, capture):
    import UnityPy
    from UnityPy.export.ShaderConverter import ShaderSubProgram
    from UnityPy.helpers import CompressionHelper
    from UnityPy.streams import EndianBinaryReader

    expected, metadata = submitted(capture)
    expected_programs = submitted_programs(metadata)
    report = dict(schema=1, bundle=str(Path(bundle).resolve()), sha256=sha256(bundle),
                  submittedSHA256=sha256(capture), parser="UnityPy " + UnityPy.__version__,
                  shaders=[], failures=[], submissionMetadata=metadata)
    seen = set()
    for obj in UnityPy.load(str(bundle)).objects:
        if obj.type.name != "Shader":
            continue
        tree = obj.read_typetree()
        form = tree["m_ParsedForm"]
        name = form["m_Name"]
        shader = dict(shader=name, passes=[], expectedSetAvailable=any(k[0] == name for k in expected))
        try:
            platform = tree["platforms"].index(4)
            blob = bytes(tree["compressedBlob"])
            segments = []
            for offset, compressed, expanded in zip(tree["offsets"][platform], tree["compressedLengths"][platform], tree["decompressedLengths"][platform]):
                if offset + compressed > len(blob):
                    raise ValueError("Compressed segment exceeds blob")
                segment = CompressionHelper.decompress_lz4(blob[offset:offset + compressed], expanded)
                if len(segment) != expanded:
                    raise ValueError("Wrong decompressed segment size")
                segments.append(segment)
            count = struct.unpack_from("<I", segments[0])[0]
            if 4 + count * 12 > len(segments[0]):
                raise ValueError("Invalid native program directory")
            native = []
            for index in range(count):
                offset, size, segment = struct.unpack_from("<III", segments[0], 4 + index * 12)
                if segment >= len(segments) or offset + size > len(segments[segment]):
                    raise ValueError("Native program segment/range out of bounds")
                # Unity 2019.3+ offsets are relative to EACH segment, not one concatenated buffer.
                reader = EndianBinaryReader(segments[segment][offset:offset + size], endian="<")
                native.append(ShaderSubProgram(reader))
            for sub in form["m_SubShaders"]:
                for pass_index, p in enumerate(sub["m_Passes"]):
                    names = {index: label for label, index in p["m_NameIndices"]}
                    # ShaderSnippetData names unnamed passes by their ordinal,
                    # while the serialized ShaderLab name remains empty.
                    pass_name = p["m_State"]["m_Name"] or "Pass " + str(pass_index)
                    stages = {}
                    for stage in STAGES:
                        items = p.get("prog" + stage, {}).get("m_SubPrograms", [])
                        if not items:
                            continue
                        key = (name, pass_name, stage)
                        rows, actual, identities = [], set(), set()
                        for item in items:
                            keywords = tuple(sorted({names[i] for field in ("m_GlobalKeywordIndices", "m_LocalKeywordIndices") for i in item.get(field, [])}))
                            tier = item["m_ShaderHardwareTier"]
                            identity = (tier, keywords)
                            if identity in identities:
                                raise ValueError("Duplicate serialized program: " + repr((key, identity)))
                            identities.add(identity)
                            actual.add(keywords)
                            row = dict(keywords=keywords, hardwareTier=tier, validDXBC=False)
                            try:
                                row.update(dxbc(bytes(native[item["m_BlobIndex"]].m_ProgramCode), stage))
                                row["validDXBC"] = True
                            except (ValueError, IndexError, struct.error) as error:
                                report["failures"].append(f"{key} {keywords}: {error}")
                            rows.append(row)
                        seen.add(key)
                        result = dict(programs=len(rows), native=rows)
                        if shader["expectedSetAvailable"]:
                            want = expected.get(key, set())
                            want_programs = expected_programs.get(key, set())
                            delivered_programs = expand_common_tier(identities, want_programs)
                            result.update(submitted=len(want_programs), missing=sorted(want - actual), unexpected=sorted(actual - want),
                                missingPrograms=[dict(hardwareTier=t, keywords=k) for t, k in sorted(want_programs - delivered_programs)],
                                unexpectedPrograms=[dict(hardwareTier=t, keywords=k) for t, k in sorted(delivered_programs - want_programs)])
                            if want_programs != delivered_programs:
                                report["failures"].append(f"{key}: submitted/delivered mismatch")
                        stages[stage] = result
                    shader["passes"].append(dict(name=pass_name, stages=stages))
        except (ValueError, KeyError, IndexError, struct.error) as error:
            report["failures"].append(name + ": " + str(error))
        report["shaders"].append(shader)
    report["missingStages"] = sorted(set(expected) - seen)
    report["failures"].extend(str(k) + ": missing stage" for k in set(expected) - seen)
    report["failedVariants"] = [dict(shader=s["shader"], passName=p["name"], stage=stage, **program)
        for s in report["shaders"] for p in s["passes"] for stage, data in p["stages"].items() for program in data.get("missingPrograms", [])]
    report["failedVariants"].extend(dict(shader=key[0], passName=key[1], stage=key[2], hardwareTier=tier, keywords=keywords)
        for key in set(expected) - seen for tier, keywords in sorted(expected_programs[key]))
    report["failedVariants"].extend(dict(shader=s["shader"], passName=p["name"], stage=stage,
        hardwareTier=program["hardwareTier"], keywords=program["keywords"], reason="invalid_DXBC")
        for s in report["shaders"] for p in s["passes"] for stage, data in p["stages"].items()
        for program in data["native"] if not program["validDXBC"])
    report["modernPrograms"] = sum(v["programs"] for s in report["shaders"] if s["shader"] in MODERN for p in s["passes"] for v in p["stages"].values())
    report["totalPrograms"] = sum(v["programs"] for s in report["shaders"] for p in s["passes"] for v in p["stages"].values())
    report["unverifiedSubmissionShaders"] = [s["shader"] for s in report["shaders"] if not s["expectedSetAvailable"]]
    report["status"] = "failed" if report["failures"] else "passed"
    return report


def audit_zip(path, bundle, manifest):
    report = dict(zipmod=str(Path(path).resolve()), sha256=sha256(path), failures=[])
    with zipfile.ZipFile(path) as archive:
        names = [n.replace("\\", "/").lower() for n in archive.namelist()]
        if len(set(names)) != len(names):
            report["failures"].append("Duplicate/case-colliding zip entries")
        bad = archive.testzip()
        if bad:
            report["failures"].append("CRC failure: " + bad)
        for entry, expected in ((BUNDLE_ENTRY, bundle), ("manifest.xml", manifest)):
            if names.count(entry) != 1:
                report["failures"].append("Missing or ambiguous zip entry: " + entry)
                continue
            with archive.open(archive.namelist()[names.index(entry)]) as stream:
                digest = hashlib.file_digest(stream, "sha256").hexdigest()
            report[entry] = dict(actual=digest, expected=sha256(expected))
            if digest != sha256(expected):
                report["failures"].append("Stale/wrong zip payload: " + entry)
        root = ET.parse(manifest).getroot()
        declared = {"abdata/" + p.attrib["AssetBundle"].lower() for p in root.iter() if "AssetBundle" in p.attrib}
        for entry in declared:
            if entry not in names:
                report["failures"].append("Manifest references missing bundle: " + entry)
    report["status"] = "failed" if report["failures"] else "passed"
    return report


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--submitted", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--zipmod", type=Path)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--dependencies", type=Path, help="Optional pinned UnityPy installation directory")
    parser.add_argument("--baseline-submitted", type=Path, help="Compare retained keywords, tiers and platform defines, not a hardcoded count")
    args = parser.parse_args()
    if args.dependencies:
        sys.path.insert(0, str(args.dependencies.resolve()))
    try:
        report = audit_bundle(args.bundle, args.submitted)
        if args.baseline_submitted:
            _, baseline = submitted(args.baseline_submitted)
            shaders = {row["shader"] for row in baseline}
            before = submission_signature(baseline)
            after = submission_signature(report["submissionMetadata"], shaders)
            report["baselineSubmission"] = dict(missing=sorted(before - after), added=sorted(after - before))
            if before != after:
                report["failures"].append("Submission/configuration differs from frozen baseline")
                report["status"] = "failed"
        if args.zipmod:
            if not args.manifest:
                parser.error("--zipmod requires --manifest")
            report["packaging"] = audit_zip(args.zipmod, args.bundle, args.manifest)
            report["failures"].extend(report["packaging"]["failures"])
            if report["failures"]:
                report["status"] = "failed"
    except Exception as error:
        report = dict(status="failed", failures=[repr(error)])
    save(args.output, report)
    print(json.dumps({k: report[k] for k in ("status", "modernPrograms", "totalPrograms", "failures") if k in report}))
    return int(report["status"] != "passed")


if __name__ == "__main__":
    raise SystemExit(main())
