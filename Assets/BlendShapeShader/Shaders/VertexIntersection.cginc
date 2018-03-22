uniform sampler2D _CameraDepthTexture;
uniform float _BlendShapeBackDistanceMultiplier;
uniform float _BlendShapeForwardDistanceMultiplier;
uniform float _BlendShapeCameraActivationDistance;
uniform float _BlendShapeBackActivationDistance;
uniform float _BlendShapeForwardActivationDistance;
uniform float _BlendShapeCameraDistanceMultiplier;
float GetVertexIntersection(float4 vertex, out float cameraIntersect) {
	float4 pos = UnityObjectToClipPos(vertex);
    float4 screenPos = ComputeScreenPos(pos);
    float depth = -UnityObjectToViewPos(vertex).z;
    float4 samplePosition = float4(screenPos.xy / screenPos.w,0,0);
    float screenDepth = Linear01Depth(tex2Dlod(_CameraDepthTexture, samplePosition).r)*_ProjectionParams.z;
    float diff = (screenDepth - depth);
    float intersect;
    if ( diff > 0 ) {
    	intersect = saturate((_BlendShapeForwardActivationDistance - abs(diff)*_BlendShapeForwardDistanceMultiplier)/_BlendShapeForwardActivationDistance);
    } else {
    	intersect = saturate((_BlendShapeBackActivationDistance - abs(diff)*_BlendShapeBackDistanceMultiplier)/_BlendShapeBackActivationDistance);
    }
    cameraIntersect = saturate((_BlendShapeCameraActivationDistance-abs((depth-_ProjectionParams.y)*_BlendShapeCameraDistanceMultiplier)/_BlendShapeCameraActivationDistance));
    return intersect;
}