Shader "Custom/EyeBall" {
	Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Emission ("Emission", Range(0,1)) = 1
        _Glossiness ("Smoothness", Range(0,1)) = 1
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+452"}
        Stencil {
            Ref 247
            Comp always
            Pass replace
        }
		CGPROGRAM
        #pragma surface surf Standard
        sampler2D _MainTex;
        half _Glossiness;
        half _Emission;
        half _Metallic;
        fixed4 _Color;
        struct Input {
            float2 uv_MainTex;
        };
        void surf (Input IN, inout SurfaceOutputStandard o) {
        	fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Emission = c.rgb * _Emission;
			o.Smoothness = _Glossiness;
			o.Metallic = _Metallic;
		}
        ENDCG
    } 
    Fallback "Diffuse"
}