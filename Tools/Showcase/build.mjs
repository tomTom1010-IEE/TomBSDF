import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';

const { marked } = await import(process.env.MARKED_MODULE || 'marked');
const sharp = (await import(process.env.SHARP_MODULE || 'sharp')).default;
const [rootArgument, ...reports] = process.argv.slice(2);
if (!rootArgument || reports.length !== 3) throw new Error('Usage: node build.mjs REPOSITORY FOUNDATION_REPORT SURFACE_REPORT SCENE_REPORT');
const root = path.resolve(rootArgument);
const docs = path.join(root, 'docs');
const modulePath = path.join(root, 'Assets/Mods/TomShadersBSDF');
const site = 'https://tomtom1010-iee.github.io/TomBSDF/';
const github = 'https://github.com/tomTom1010-IEE/TomBSDF';
const expectedBundle = '0904d5aa53b43639d02660c040ae8a08d1774c38af965ceefe0335c22890c200';
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const escape = text => String(text).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
const write = (file, content) => fs.writeFile(path.join(root, file), content, 'utf8');
const groups = [
  ['01-material', 'Hard-Surface Materials', 'Four independent starting looks. These are examples, not automatically applied character presets.'],
  ['02-roughness', 'Metallic and Roughness', 'The same copper-like conductor at four perceptual roughness values.'],
  ['03-anisotropy', 'Anisotropy and Tangent Direction', 'An isotropic control followed by three anisotropic lobe directions.'],
  ['04-coat', 'Independent Clearcoat Layer', 'Coverage and roughness change a separate coat and the underlying layer transport.'],
  ['05-thin-film', 'Thin-Film Interference', 'One dark dielectric and coat, with film disabled or three thicknesses in nanometers.'],
  ['06-normals', 'Base, Detail and Coat Normals', 'Known procedural RGB direction maps demonstrate independent normal frames.'],
  ['07-coverage', 'Cutout, Coverage Alpha and Back/Front', 'An opaque checker isolates geometric coverage; it is not a glass transmission model.'],
  ['08-glints', 'Statistical Glints', 'UV-anchored substrate direct-light reflection with fixed seed 17. Probe and rectangle response remains smooth.'],
  ['09-pom', 'POM and Local Height Shadows', 'A shared brick height / color / normal set under a grazing key. POM does not displace the silhouette.'],
  ['10-tess', 'Real Tessellation and Displacement', 'White-envelope, inward-black world-meter displacement, including the separate CutoutTess entry.'],
  ['11-glass', 'Finite Glass and Screen Refraction', 'Reflection, supplied thickness, absorption and bounded rough screen transmission over opaque background data.'],
  ['12-lighting', 'Native, Environment and Area Lighting', 'Independent sources, shown separately. The rectangle is a companion-enabled, unshadowed emitter.'],
  ['13-shadows', 'Native Real-Time Shadows', 'A shadow-only blocker isolates native directional and point-map reception. No extra missing-map rendering.']
];

await fs.mkdir(docs, { recursive: true });
const images = [];
const batches = [];
for (const directory of reports) {
  const report = JSON.parse(await fs.readFile(path.join(directory, 'showcase.json'), 'utf8'));
  if (report.status !== 'passed' || report.bundleSHA256 !== expectedBundle) throw new Error(`Unaccepted source report: ${directory}`);
  batches.push({ batch: report.batch, unity: report.unity, gpu: report.gpu, sourceReport: path.basename(directory) });
  for (const image of report.images) {
    if (!/^\d{3}-\d{2}\.png$/.test(image.file) || image.width !== 768 || image.height !== 768) throw new Error('Unexpected image contract');
    const bytes = await fs.readFile(path.join(directory, image.file));
    const metadata = await sharp(bytes).metadata();
    if (metadata.width !== 768 || metadata.height !== 768 || !(image.mean > 0)) throw new Error(`Invalid capture: ${image.file}`);
    await fs.writeFile(path.join(docs, image.file), bytes);
    images.push({ ...image, sha256: sha(bytes) });
  }
}
images.sort((a, b) => a.number - b.number);
if (images.length !== 52 || images.some((image, index) => image.number !== index + 1)) throw new Error('Expected 52 unique ordered images');
for (let i = 1; i <= 13; i++) if (images.filter(image => image.group === i).length !== 4) throw new Error('Incomplete comparison group');
await write('docs/showcase-data.json', JSON.stringify({
  schemaVersion: 1, version: '0.2.0 RC1', bundleSHA256: expectedBundle,
  display: 'Shared Reinhard x/(1+x), then sRGB; no per-image exposure, generated artwork or retouching.',
  scope: 'Actual packaged RC1 shaders, isolated Editor GPU illustrations. Not in-game screenshots or a new performance certification.',
  batches, groups: groups.map(([id, title, description]) => ({ id, title, description })), images
}, null, 2) + '\n');

const font = 'Segoe UI, sans-serif';
const textSvg = (width, height, content) => Buffer.from(`<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg"><style>text{font-family:${font};letter-spacing:0}</style>${content}</svg>`);
for (let index = 0; index < groups.length; index++) {
  const entries = images.filter(image => image.group === index + 1);
  const layers = [];
  for (let col = 0; col < 4; col++) {
    layers.push({ input: await sharp(path.join(docs, entries[col].file)).resize(488, 488, { fit: 'contain' }).png().toBuffer(), left: col * 512 + 12, top: 12 });
    layers.push({ input: textSvg(488, 78, `<text x="0" y="28" fill="#e8ebea" font-size="20">${escape(entries[col].title)}</text><text x="0" y="56" fill="#aab6ae" font-size="16">${escape(entries[col].shader)}</text>`), left: col * 512 + 12, top: 502 });
  }
  await sharp({ create: { width: 2048, height: 586, channels: 3, background: '#101312' } }).composite(layers).png().toFile(path.join(docs, `${groups[index][0]}-board.png`));
}
const overviewNumbers = [1, 2, 3, 4, 17, 19, 22, 24, 29, 32, 38, 40, 42, 43, 46, 48];
const overviewLayers = [];
for (let i = 0; i < overviewNumbers.length; i++) {
  const image = images[overviewNumbers[i] - 1];
  overviewLayers.push({ input: await sharp(path.join(docs, image.file)).resize(360, 360, { fit: 'contain' }).png().toBuffer(), left: (i % 4) * 384 + 12, top: Math.floor(i / 4) * 416 + 12 });
  overviewLayers.push({ input: textSvg(360, 42, `<text x="0" y="25" fill="#e8ebea" font-size="15">${escape(image.title)}</text>`), left: (i % 4) * 384 + 12, top: Math.floor(i / 4) * 416 + 375 });
}
await sharp({ create: { width: 1536, height: 1664, channels: 3, background: '#101312' } }).composite(overviewLayers).png().toFile(path.join(docs, 'Overview.png'));

function document(title, body, file, { script = '', description = 'TomBSDF physically based materials for Koikatsu Sunshine.' } = {}) {
  return `<!doctype html>\n<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escape(title)}</title><meta name="description" content="${escape(description)}"><meta name="color-scheme" content="dark light"><meta property="og:title" content="${escape(title)}"><meta property="og:description" content="${escape(description)}"><meta property="og:image" content="${site}Overview.png"><meta property="og:type" content="website"><link rel="canonical" href="${site}${file}"><link rel="stylesheet" href="style.css"></head><body><a class="skip-link" href="#content">Skip to content</a>${body}<footer><p>TomBSDF 0.2.0 RC1 · Unity 2019.4.9f1 · Built-in Forward · D3D11</p><p>Actual packaged-shader Editor renders; fixed display transform. Not an in-game GPU benchmark. <a href="${github}">Source</a> · <a href="CaptureNotes.html">Capture notes</a> · <a href="${github}/blob/main/LICENSE">License</a></p></footer>${script ? `<script src="${script}" defer></script>` : ''}</body></html>\n`;
}
const nav = `<nav aria-label="Main"><a href="index.html">Sphere showcase</a><a href="UserManual.html">User manual</a><a href="Reference.html">Parameter reference</a><a href="Overview.png">Overview</a><a href="${github}">GitHub</a></nav>`;
let gallery = `<header><h1>TomBSDF Sphere Showcase</h1><p>Physically based hard-surface shaders for Koikatsu Sunshine. 52 actual Unity GPU renders in 13 comparisons, using one shared UV sphere and fixed exposure.</p>${nav}<p class="scope">Actual packaged RC1 shaders. Checker backgrounds and shadow-only blockers isolate each feature. Editor illustrations, not in-game benchmarks or forced presets.</p><details class="comparison-nav"><summary>Comparison index</summary><nav aria-label="Comparisons">${groups.map(([id, title]) => `<a href="#${id}">${escape(title)}</a>`).join('')}</nav></details></header><main id="content">`;
for (let index = 0; index < groups.length; index++) {
  const [id, title, description] = groups[index];
  gallery += `<section id="${id}"><h2>${escape(title)}</h2><p class="scope">${escape(description)}</p><div class="grid">`;
  for (const image of images.filter(item => item.group === index + 1)) {
    gallery += `<figure><a href="${image.file}"><img loading="${index === 0 ? 'eager' : 'lazy'}" width="768" height="768" src="${image.file}" alt="${escape(image.title)}: ${escape(image.shader)} sphere"></a><figcaption><b>${escape(image.title)}</b><span class="shader-name">${escape(image.shader)}</span></figcaption><details><summary>Parameters and lighting</summary><p>${escape(image.description)}</p><p>${escape(image.lighting)}</p><div class="table-scroll"><table><caption class="scope">Recorded values; color constants are linear RGB</caption><tbody>${image.properties.map(property => `<tr><td><code>${escape(property.name)}</code></td><td>${escape(property.value)}</td></tr>`).join('')}</tbody></table></div></details></figure>`;
  }
  gallery += `</div><p><a href="${id}-board.png">Full-resolution comparison</a> · <a href="UserManual.html">Material guide</a></p></section>`;
}
gallery += '</main>';
const galleryHtml = document('TomBSDF Sphere Showcase', gallery, '', { description: '52 real Unity GPU renders: metallic, anisotropy, coat, thin film, normals, Alpha, Glints, POM, Tess, glass and lighting for KKS.' });
await write('docs/index.html', galleryHtml);
await write('docs/Gallery.html', galleryHtml.replace(`href="${site}"`, `href="${site}Gallery.html"`));

const chapters = ['Installation.md', 'Material-Guide.md', 'HardSurface-Release.md', 'KKS-ME-Acceptance.md', 'Troubleshooting.md', 'Build-Guide.md', 'Release-Status.md'];
const chapterContent = [];
for (const chapter of chapters) {
  const content = await fs.readFile(path.join(modulePath, 'Documents', chapter), 'utf8');
  chapterContent.push(content.replace(/^(#{1,5}) /gm, '$1# '));
}
const manual = `# TomBSDF User Manual\n\nFor **0.2.0 RC1**, KKS, Unity 2019.4.9f1 runtime, Built-in Forward / D3D11. Companion **0.6.0 + matching Runtime** is optional for core shading. Property names follow ME without a leading underscore.\n\nThe maintainer reported KKS / ME acceptance passed on 2026-10-25. Showcase illustrations are separate Editor renders, not player frame-time measurements.\n\n${chapterContent.join('\n\n')}\n`;
await write('docs/TomBSDF-UserManual.en.md', manual.replace(/\]\(([^#:()]+\.(?:md|json))(#[^)]*)?\)/g, (_match, target, fragment = '') => `](${github}/blob/main/Assets/Mods/TomShadersBSDF/Documents/${target}${fragment})`).trimEnd() + '\n');
const slugs = new Map();
const slug = text => String(text).replace(/<[^>]*>/g, '').replace(/[^a-z0-9\s-]/gi, '').trim().toLowerCase().replace(/\s+/g, '-');
function renderMarkdown(source) {
  slugs.clear();
  const renderer = new marked.Renderer();
  renderer.heading = function(token) {
    const title = this.parser.parseInline(token.tokens);
    const base = slug(token.text), repeat = slugs.get(base) || 0;
    slugs.set(base, repeat + 1);
    return `<h${token.depth} id="${base}${repeat ? '-' + repeat : ''}">${title}</h${token.depth}>\n`;
  };
  return marked.parse(source, { renderer, gfm: true });
}
const chapterAnchors = Object.fromEntries(chapters.map((chapter, index) => [chapter, slug(chapterContent[index].split('\n')[0].replace(/^#+\s*/, ''))]));
function rewriteLinks(html) {
  return html.replace(/href="([^"#:]+\.(?:md|json))(#[^"]*)?"/g, (_match, target, fragment = '') => {
    if (['showcase-data.json', 'parameter-data.json'].includes(target)) return `href="${target}${fragment}"`;
    if (target.startsWith('http')) return `href="${escape(target + fragment)}"`;
    if (chapterAnchors[target]) return `href="UserManual.html#${chapterAnchors[target]}"`;
    return `href="${github}/blob/main/Assets/Mods/TomShadersBSDF/Documents/${escape(target + fragment)}"`;
  });
}
const toc = `<nav aria-label="Manual chapters"><ul class="toc">${chapters.map((chapter, index) => `<li><a href="#${chapterAnchors[chapter]}">${escape(chapterContent[index].split('\n')[0].replace(/^#+\s*/, ''))}</a></li>`).join('')}</ul></nav>`;
await write('docs/UserManual.html', document('TomBSDF User Manual', `<header>${nav}</header><main id="content"><article>${toc}${rewriteLinks(renderMarkdown(manual))}</article></main>`, 'UserManual.html'));

const parameters = JSON.parse(await fs.readFile(path.join(docs, 'parameter-data.json'), 'utf8'));
if (parameters.shaders.length !== 8 || parameters.shaders.reduce((n, item) => n + item.properties.length, 0) !== 592) throw new Error('Parameter contract changed; review reference scope before publishing');
let reference = `<header><h1>TomBSDF Parameter Reference</h1><p>ME names, categories and declared ranges from the shipped manifest, with the matching per-shader tooltip text. Defaults not declared in the manifest remain shader defaults.</p>${nav}</header><main id="content"><div class="reference-tools"><label class="search">Search parameters<input id="parameter-search" type="search" placeholder="Name, category or description" autocomplete="off"></label><label>Shader<select id="shader-filter"><option value="">All modern shaders and rectangle control</option>${parameters.shaders.map(shader => `<option value="${escape(shader.name)}">${escape(shader.name)}</option>`).join('')}</select></label></div><p id="result-count" class="scope" role="status" aria-live="polite">592 parameters</p>`;
for (const shader of parameters.shaders) {
  reference += `<section data-parameter-shader="${escape(shader.name)}"><h2>${escape(shader.name)}</h2>`;
  const categories = [...new Set(shader.properties.map(property => property.category))];
  for (const category of categories) {
    reference += `<div data-parameter-group><h3>${escape(category)}</h3><table class="parameter-table"><thead><tr><th scope="col">Parameter</th><th scope="col">Type / range / default</th><th scope="col">Meaning</th></tr></thead><tbody>`;
    for (const property of shader.properties.filter(item => item.category === category)) {
      reference += `<tr data-parameter><td><code>${escape(property.name)}</code></td><td>${escape(property.type)}${property.range ? `<br>Range: ${escape(property.range)}` : ''}<br>Default: ${escape(property.default || 'Shader default')}</td><td>${escape(property.description)}</td></tr>`;
    }
    reference += '</tbody></table></div>';
  }
  reference += '</section>';
}
reference += '</main>';
await write('docs/Reference.html', document('TomBSDF Parameter Reference', reference, 'Reference.html', { script: 'reference.js' }));

const captureNotes = `# Showcase Capture Notes\n\n52 actual GPU images, captured from the accepted RC1 Bundle, not generated illustrations or photographs. All source images are 768x768 and copied byte-for-byte into this gallery. Comparison boards resize uniformly and add captions outside the render.\n\n## Shared Conditions\n\n- Unity ${batches[0].unity}, ${batches[0].gpu}, D3D11, Gamma authoring with the explicit KKSLinear-v1 linear output contract.\n- Standard Unity UV sphere, orthographic camera at (0,0,-3), size 0.7; no automatic exposure / grading.\n- Default directional key intensity 0.85, rotation (25,-32,0), fixed analytic studio cubemap and ambient SH. Native additional light / shadow and isolated environment groups explicitly change light sources.\n- POM uses a documented grazing key (65,-55,0). Coverage / glass use opaque checkers. Native shadows use a shadow-only blocker. The rectangle requires the matching temporary scene service.\n- One global display transform: Reinhard x/(1+x), followed by sRGB. No per-image exposure, contrast, AI enhancement or content retouching.\n- Known procedural RGB ripple maps illustrate normals; a shared brick set illustrates POM; periodic R height illustrates Tess. Settings identify named procedural maps rather than claiming a user texture pack.\n\n## Provenance\n\nBundle SHA256: \`${expectedBundle}\`. The material's shader-owned tables come from that Bundle. Public [showcase data](showcase-data.json) records the source image SHA256, all captured public material settings, light notes and source run IDs. [Parameter data](parameter-data.json) comes from the shipped manifest and tooltip catalog.\n\nThe full private developer fixture / raw GPU and compiler evidence remains outside this repository. No user character or scene is used. These images do not replace manual KKS acceptance or establish whole-scene GPU performance.\n\n## Interpretation\n\nGroups are controlled illustrations, not a single scene with every feature enabled. Do not interpret black shadow regions without indirect fill as colored-light transport, Back/Front as OIT, POM as silhouette geometry, a finite glass sphere as a solid lens, or Glints as emission. The [user manual](UserManual.html) lists approximation and fallback boundaries.\n`;
await write('docs/Capture-Notes.md', captureNotes.replaceAll('\`', '`'));
await write('docs/CaptureNotes.html', document('TomBSDF Capture Notes', `<header>${nav}</header><main id="content"><article>${rewriteLinks(renderMarkdown(captureNotes.replaceAll('\`', '`')))}</article></main>`, 'CaptureNotes.html'));

const readme = `# Tom BSDF\n\nPhysically based hard-surface shaders for Koikatsu Sunshine and Unity 2019.4 Built-in Forward.\n\n**[Interactive showcase](${site})** · [User manual](${site}UserManual.html) · [Parameter reference](${site}Reference.html) · [Source and build guide](Assets/Mods/TomShadersBSDF/Documents/Build-Guide.md)\n\n52 actual Unity GPU renders in 13 comparisons. Every subject uses the same standard UV sphere and fixed exposure. No per-image brightening or generated illustrations. Full-size images and recorded material settings are available in the showcase.\n\nSeven modern entries cover opaque / cutout surfaces, premultiplied Alpha, Back/Front transparency, independent finite glass and two separate Tess displacement variants. Shared features include compensated GGX / Smith, EON diffuse, anisotropy, Probe / SH, AO, detail normals, specular AA, layered coat / absorption, thin film, POM local shadows and statistical Glints on supported entries.\n\n## Use and Scope\n\n- **[Download the complete KKS package](${github}/releases/tag/v0.2.0-rc1)**. Includes both zipmods, matching Companion / Runtime and optional Probe tools. [Release notes and upgrade instructions](RELEASE-NOTES-0.2.0-RC1.md).\n- Current package: **0.2.0 RC1**. Packaged Editor auditing passed; the maintainer reported KKS / ME acceptance passed. [Release status](Assets/Mods/TomShadersBSDF/Documents/Release-Status.md).\n- This repository is a rebuildable KKS source overlay, not a complete Unity project or an installable zipmod. [Installation and DLL paths](Assets/Mods/TomShadersBSDF/Documents/Installation.md). Compiled game packages are separate artifacts, not Git source.\n- Core colors / physical shading do not need extra plugins. Rectangles, screen refraction, transparent native-map reuse and automatic displacement bounds use optional Companion **0.6.0 + matching Runtime**.\n- Coverage is not optical transmission. Glass is a finite screen / parallel-slab approximation, not full GGX BTDF, nested media or a solid lens. Rectangles are unshadowed.\n- Native Probe / SH needs scene data. The optional Studio Probe tool is independent; no V+ / TomShadersX pack is required. No modern KK / Unity 5.6 port is included.\n- Screenshot promotion affects area integration only, not film / POM / Tess. The showcase is a visual reference, not forced character presets or an in-game performance claim.\n\nCoverage uses an opaque checker, glass uses the matching scene-buffer service, and shadow tests use a shadow-only blocker. The grazing-light POM group is identified explicitly. [Capture notes](${site}CaptureNotes.html) explain the common display transform and image provenance.\n\n${groups.map(([id, title]) => `## ${title}\n\n[![${title}](docs/${id}-board.png)](${site}#${id})`).join('\n\n')}\n\n## Development and License\n\nInstall Git LFS before cloning and run \`git lfs pull\`. Required prefabs, materials, Runtime, native LUTs and matching metadata are tracked; two large LUTs use LFS. Build outputs, cache, test intermediates, duplicate shader backups and obsolete tools remain excluded. Active legacy xukmi compatibility paths are retained.\n\nRead the [build guide](Assets/Mods/TomShadersBSDF/Documents/Build-Guide.md), [documentation index](Assets/Mods/TomShadersBSDF/Documents/README.md), [contribution notes](CONTRIBUTING.md) and [support guide](SUPPORT.md). Before local edits, run \`pwsh -File Tools/Validate-SourcePublication.ps1\`. The old Unity compiler's cold-build issue is not declared fixed.\n\nThe repository [LICENSE](LICENSE), inherited [module MIT notice](Assets/Mods/TomShadersBSDF/LICENSE) and [LTC notice](Assets/Mods/TomShadersBSDF/ThirdParty/LTC-LICENSE.txt) are preserved.\n`;
await write('README.md', readme.replaceAll('\`', '`'));
console.log(JSON.stringify({ status: 'built', images: images.length, comparisons: groups.length, parameters: 592, pages: ['index.html', 'Gallery.html', 'UserManual.html', 'Reference.html', 'CaptureNotes.html'] }, null, 2));
