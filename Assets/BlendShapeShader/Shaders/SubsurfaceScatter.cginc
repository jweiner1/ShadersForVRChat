uniform float _Distortion;
uniform float _Scale;
uniform float _Power;
inline fixed3 LightingStandardTranslucent(fixed3 c, float3 viewDir, float3 n, float3 lightDirection, fixed3 lightColor, sampler2D tex, float2 uv) {
	// --- Translucency ---
	float3 L = lightDirection;
	float3 V = viewDir;
	float3 N = n;

	float3 H = normalize(L + N * _Distortion);
	float I = saturate(dot(V, -H)) * _Scale;

	// Final add
	c.rgb = c.rgb + lightColor * I * tex2D(tex, float4(uv.xy,0,0));
	return saturate(c);
}