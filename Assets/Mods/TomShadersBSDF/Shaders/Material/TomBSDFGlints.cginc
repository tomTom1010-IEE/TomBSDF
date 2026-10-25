#ifndef TOM_BSDF_GLINT_MATERIAL_INCLUDED
#define TOM_BSDF_GLINT_MATERIAL_INCLUDED
#include "../Core/TomBSDFGlints.cginc"

UNITY_DECLARE_TEX2D_NOSAMPLER(_GlintMask);
float4 _GlintMask_ST;
float _GlintWeight, _GlintDensity, _GlintContrast, _GlintSeed;

void TomGlintGrid(float2 uv, int3 grid, float allocation, uint seed,
    out uint3 keys, out float3 trials)
{
    // A ratio-zero grid is invariant to its otherwise arbitrary orientation.
    int orientation = grid.y == 0 ? 0 : (int)((uint)grid.z & 7u);
    float angle = orientation * (TOM_BSDF_PI / 8.0);
    float sn, cs; sincos(angle, sn, cs);
    float2 local = float2(dot(uv,float2(cs,sn)),dot(uv,float2(-sn,cs)));
    local *= exp2(-float2(grid.x+grid.y,grid.x));
    uint gridSeed = TomGlintHash(seed ^ asuint(grid.x) ^ TomGlintHash(asuint(grid.y)) ^ TomGlintHash((uint)orientation));
    int2 a,b,c; float3 weights;
    TomGlintTriangle(local,a,b,c,weights);
    keys = uint3(TomGlintKey(a,gridSeed),TomGlintKey(b,gridSeed),TomGlintKey(c,gridSeed));
    trials = allocation * weights;
}

TomGlintFootprint TomReadGlints(TomSurfaceCoordinates c, TomBSDFMaterial intrinsic)
{
    TomGlintFootprint result = (TomGlintFootprint)0;
    if (_GlintWeight <= 0.0) return result;
    float mask = TomLayerMap(TomSampleSurfaceData(_GlintMask,sampler_RoughnessMap,_GlintMask_ST,c).r);
    result.weight = saturate(_GlintWeight) * mask;
    if (result.weight <= 0.0) return result;
    float density = pow(10.0,clamp(_GlintDensity,0.0,8.0));
    float scale = sqrt(density);
    float2 dx = c.dx * scale, dy = c.dy * scale;
    float xx = dx.x*dx.x + dy.x*dy.x, yy = dx.y*dx.y + dy.y*dy.y;
    float xy = dx.x*dx.y + dy.x*dy.y;
    float discriminant = sqrt(max((xx-yy)*(xx-yy)+4.0*xy*xy,0.0));
    float majorSquared = max(0.5*(xx+yy+discriminant),1e-12);
    float determinant = abs(dx.x*dy.y - dx.y*dy.x);
    float minorSquared = max(determinant*determinant/majorSquared,1e-12);
    result.count = max(determinant,1e-8);
    result.ratio = pow(10.0,-3.0*saturate(_GlintContrast));
    result.intrinsicAlphaSquared = pow(intrinsic.roughness,4.0);
    // A finite derivative fallback is for degenerate charts, not an opaque mask.
    float2 direction = abs(xy)>1e-12 ? TomSafeNormalize(float3(xy,majorSquared-xx,0)).xy : (xx>=yy ? float2(1,0) : float2(0,1));
    float angle = atan2(direction.y,direction.x);
    if (angle<0.0) angle+=TOM_BSDF_PI;
    float ratioLevel = max(0.5*log2(majorSquared/minorSquared),0.0);
    float3 parameter = float3(clamp(0.5*log2(minorSquared),-16.0,24.0),min(ratioLevel,24.0),angle*(8.0/TOM_BSDF_PI));
    int3 baseGrid = (int3)floor(parameter);
    float3 f = frac(parameter);
    // Four tetrahedron vertices instead of eight trilinear parameterizations.
    int first = f.x>=f.y ? (f.x>=f.z ? 0 : 2) : (f.y>=f.z ? 1 : 2);
    int last = f.x<f.y ? (f.x<f.z ? 0 : 2) : (f.y<f.z ? 1 : 2);
    if (first==last) last=first==0 ? 2 : first-1;
    int middle=3-first-last;
    int3 stepFirst=first==0 ? int3(1,0,0) : (first==1 ? int3(0,1,0) : int3(0,0,1));
    int3 stepMiddle=middle==0 ? int3(1,0,0) : (middle==1 ? int3(0,1,0) : int3(0,0,1));
    float4 weights=float4(1.0-f[first],f[first]-f[middle],f[middle]-f[last],f[last]);
    int3 grid0=baseGrid,grid1=baseGrid+stepFirst,grid2=baseGrid+stepFirst+stepMiddle,grid3=baseGrid+1;
    if(grid0.y==0)grid0.z=0;
    if(grid1.y==0)grid1.z=0;
    if(grid2.y==0)grid2.z=0;
    if(grid3.y==0)grid3.z=0;
    // Canonical isotropic grids can coincide. Merge their trials before
    // sampling so an undefined footprint orientation cannot change variance.
    if(all(grid0==grid1)){weights.x+=weights.y;weights.y=0;}
    if(all(grid0==grid2)){weights.x+=weights.z;weights.z=0;}
    if(all(grid0==grid3)){weights.x+=weights.w;weights.w=0;}
    if(all(grid1==grid2)){weights.y+=weights.z;weights.z=0;}
    if(all(grid1==grid3)){weights.y+=weights.w;weights.w=0;}
    if(all(grid2==grid3)){weights.z+=weights.w;weights.w=0;}
    uint seed=(uint)clamp(floor(_GlintSeed+0.5),0.0,65535.0);
    float2 uv = c.uv * scale;
    TomGlintGrid(uv,grid0,result.count*weights.x,seed,result.seeds0,result.trials0);
    TomGlintGrid(uv,grid1,result.count*weights.y,seed,result.seeds1,result.trials1);
    TomGlintGrid(uv,grid2,result.count*weights.z,seed,result.seeds2,result.trials2);
    TomGlintGrid(uv,grid3,result.count*weights.w,seed,result.seeds3,result.trials3);
    return result;
}
#endif
