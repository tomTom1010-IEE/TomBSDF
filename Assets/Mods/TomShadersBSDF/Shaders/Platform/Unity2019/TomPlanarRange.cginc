#ifndef TOM_PLANAR_RANGE_INCLUDED
#define TOM_PLANAR_RANGE_INCLUDED
// N, F, near transition width, far transition width (all metres).
float TomPlanarRangeWeight(float d,float4 r) {
    float n=r.z>0?smoothstep(0,1,(d-r.x)/max(r.z,1e-8)):step(r.x,d);
    float f=r.w>0?1-smoothstep(0,1,(d-r.y)/max(r.w,1e-8)):step(d,r.y);
    return (r.x>0?n:1)*(r.y>0?f:1);
}
#endif
