uniform float _DepthBlur;
uniform sampler2D _CameraDepthTexture;
uniform float _BlendShapeBackDistanceMultiplier;
uniform float _BlendShapeForwardDistanceMultiplier;
uniform float _BlendShapeCameraActivationDistance;
float GetVertexIntersection(float4 vertex, out float cameraIntersect) {
	float4 pos = UnityObjectToClipPos(vertex);
    float4 screenPos = ComputeScreenPos(pos);
    float depth = -UnityObjectToViewPos(vertex).z;
    float4 samplePosition = float4(screenPos.xy / screenPos.w,0,0);
    float sample = tex2Dlod(_CameraDepthTexture, samplePosition).r;
    float screenDepth = Linear01Depth(sample)*_ProjectionParams.z;
    float diff = (screenDepth - depth);
    float intersect;
    if ( diff > 0 ) {
    	intersect = saturate(1 - abs(diff*_BlendShapeForwardDistanceMultiplier));
    } else {
    	intersect = saturate(1 - abs(diff*_BlendShapeBackDistanceMultiplier));
    }
    cameraIntersect = saturate(1-abs(depth*_BlendShapeCameraActivationDistance));
    return intersect;
}