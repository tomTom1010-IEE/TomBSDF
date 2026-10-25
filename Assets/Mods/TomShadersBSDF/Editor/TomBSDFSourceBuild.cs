using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Rendering;
using UnityEngine;
using UnityEngine.Rendering;

// Standalone production-source overlay helper. No fixtures or startup jobs.
public static class TomBSDFSourceBuild
{
    const string Root="Assets/Mods/TomShadersBSDF", Bundle="chara/tom/shaders/tombsdf.unity3d";
    internal static string CapturePath;
    [MenuItem("Tools/TomBSDF/Validate Source Overlay")]
    public static void Validate()
    {
        var manifest=XDocument.Load(Root+"/manifest.xml").Root;
        if(manifest.Element("game").Value!="Koikatsu Sunshine") throw new BuildFailedException("KKS overlay expected.");
        foreach(var entry in manifest.Element("MaterialEditor").Elements("Shader"))
        {
            string name=(string)entry.Attribute("Name"),path=Root+"/Prefab/"+(string)entry.Attribute("Asset")+".prefab";
            var prefab=AssetDatabase.LoadAssetAtPath<GameObject>(path);
            if(!prefab || AssetDatabase.GetImplicitAssetBundleName(path)!=Bundle) throw new BuildFailedException("Missing/misbound carrier: "+path);
            var components=prefab.GetComponentsInChildren<Transform>(true).SelectMany(t=>t.GetComponents<Component>()).ToArray();
            if(components.Any(c=>!c)) throw new BuildFailedException("Missing host/Runtime component: "+path);
            var material=prefab.GetComponentsInChildren<Renderer>(true).SelectMany(r=>r.sharedMaterials).FirstOrDefault(m=>m && m.shader && m.shader.name==name);
            if(!material || !material.shader.isSupported) throw new BuildFailedException("Unsupported carrier shader: "+name);
            foreach(var property in entry.Elements("Property"))
                if(!material.HasProperty("_"+(string)property.Attribute("Name"))) throw new BuildFailedException("Missing property on "+name);
            if(name.StartsWith("tom/BSDF",StringComparison.Ordinal))
            {
                var importer=AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(material.shader)) as ShaderImporter;
                foreach(string resource in new[]{"_TomBSDFEnergyLUT","_TomBSDFAnisoEnergyLUT","_TomBSDFFilmEnergyLUT","_TomBSDFRectLTC"})
                    if(material.HasProperty(resource) && (!importer || !importer.GetNonModifiableTexture(resource)))
                        throw new BuildFailedException("Missing shader-owned LUT: "+name+"/"+resource);
            }
        }
        Debug.Log("TomBSDF source overlay carriers/properties/resources validated; no build was run.");
    }
    [MenuItem("Tools/TomBSDF/Build Native Bundle")]
    public static void Build()
    {
        Validate();
        var assets=AssetDatabase.GetAssetPathsFromAssetBundle(Bundle);
        if(assets.Length==0) throw new BuildFailedException("Missing bundle assignments.");
        Directory.CreateDirectory("Build/abdata"); CapturePath="Build/TomBSDF-native-variants.jsonl";
        // Archive prior submissions; never combine records from different runs.
        if(File.Exists(CapturePath)) File.Move(CapturePath,CapturePath+"."+DateTime.UtcNow.ToString("yyyyMMddHHmmssfff"));
        try
        {
            var result=BuildPipeline.BuildAssetBundles("Build/abdata",new[]{new AssetBundleBuild {assetBundleName=Bundle,assetNames=assets}},
                BuildAssetBundleOptions.ForceRebuildAssetBundle|BuildAssetBundleOptions.ChunkBasedCompression|BuildAssetBundleOptions.StrictMode,BuildTarget.StandaloneWindows);
            if(!result) throw new BuildFailedException("Native bundle build failed; do not package a partial result.");
        }
        finally { CapturePath=null; }
        Debug.Log("Native BSDF bundle written. Audit actual DXBC and final zipmod before delivery; no game deployment performed.");
    }
}

// Same non-mutating quality-triplet rule as the development build guard.
public sealed class TomBSDFSourceVariantGuard : IPreprocessShaders
{
    const string RT="TOM_BSDF_AREA_REALTIME", REF="TOM_BSDF_AREA_REFERENCE";
    [Serializable] sealed class Record { public string shader,pass,stage; public string[] variants,platformDefinitions; }
    public int callbackOrder {get{return int.MaxValue;}}
    public void OnProcessShader(Shader shader,ShaderSnippetData snippet,IList<ShaderCompilerData> data)
    {
        if(!shader) return;
        if(shader.name.StartsWith("tom/BSDF",StringComparison.Ordinal)
            && snippet.passName.StartsWith("ForwardBase",StringComparison.Ordinal)
            && snippet.shaderType==ShaderType.Fragment && data.Count>0)
        {
            var groups=new Dictionary<string,HashSet<int>>();
            foreach(var variant in data)
            {
                var keys=variant.shaderKeywordSet.GetShaderKeywords().Select(k=>ShaderKeyword.GetKeywordName(shader,k)).ToArray();
                bool realtime=keys.Contains(RT),reference=keys.Contains(REF);
                if(realtime && reference) throw new BuildFailedException("Mutually exclusive TomBSDF quality keywords.");
                string key=variant.shaderCompilerPlatform+":"+variant.graphicsTier+":"+string.Join(" ",keys.Where(k=>k!=RT && k!=REF).OrderBy(k=>k));
                HashSet<int> paths;if(!groups.TryGetValue(key,out paths)) groups.Add(key,paths=new HashSet<int>());
                paths.Add(reference?2:realtime?1:0);
            }
            foreach(var group in groups) if(group.Value.Count!=3) throw new BuildFailedException("Missing TomBSDF Off/Realtime/Reference variant: "+shader.name+"/"+snippet.passName);
        }
        if(TomBSDFSourceBuild.CapturePath==null || !AssetDatabase.GetAssetPath(shader).StartsWith("Assets/Mods/TomShadersBSDF/Shaders/",StringComparison.Ordinal)) return;
        var record=new Record {shader=shader.name,pass=snippet.passName,stage=snippet.shaderType.ToString(),
            platformDefinitions=data.Select(d=>string.Join(" ",Enum.GetValues(typeof(BuiltinShaderDefine)).Cast<BuiltinShaderDefine>()
                .Where(k=>d.platformKeywordSet.IsEnabled(k)).Select(k=>k.ToString()).OrderBy(k=>k))).Distinct().ToArray(),
            variants=data.Select(d=>d.shaderCompilerPlatform+":"+d.graphicsTier+":"+string.Join(" ",d.shaderKeywordSet.GetShaderKeywords()
                .Select(k=>ShaderKeyword.GetKeywordName(shader,k)).OrderBy(k=>k))).ToArray()};
        File.AppendAllText(TomBSDFSourceBuild.CapturePath,JsonUtility.ToJson(record)+"\n");
    }
}
