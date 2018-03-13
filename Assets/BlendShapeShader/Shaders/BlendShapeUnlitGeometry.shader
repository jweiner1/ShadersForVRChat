// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/BlendShapeUnlitGeometry" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _BlendShapeMultiplier("Blend Shape Multiplier", Range(0, 100)) = 1
        _BlendShapeBackDistanceMultiplier("Blend Shape Back Distance", Range(0, 10)) = 10000
        _BlendShapeForwardDistanceMultiplier("Blend Shape Forward Distance", Range(0, 10)) = 10000
        _BlendShapeCameraActivationDistance("Blend Shape Camera Activation Distance", Range(0, 10)) = 1
    }
    SubShader {
        Tags {"Queue"="Transparent-1" "RenderType"="Opaque"}

        Pass {
	        CGPROGRAM
	        #pragma geometry geo
	        #pragma vertex vert
	        #pragma fragment frag
	        #pragma target 4.0
	        #include "UnityCG.cginc"
	        uniform float4 _Color;
	        uniform float _BlendShapeMultiplier;
	        #include "VertexIntersection.cginc"
	        struct VertexAttributes {
	            float4 vertex : POSITION;
	            float3 normal : NORMAL;
	            float4 tangent : TANGENT;
	            float2 texcoord0 : TEXCOORD0;
	            float4 texcoord1 : TEXCOORD1;
	            float4 texcoord2 : TEXCOORD2;
	            float4 texcoord3 : TEXCOORD3;
	        };

	        float3 calculatePositionOffset( VertexAttributes v ) {
	        	float cameraIntersection;
	        	float intersect = GetVertexIntersection(v.vertex, cameraIntersection);
				float3 deltaPosition = (v.texcoord1.x * normalize(v.normal)) + (v.texcoord1.y * normalize(v.tangent.xyz)) + (v.texcoord1.z * normalize(cross(v.normal,v.tangent.xyz)));
				return (deltaPosition * _BlendShapeMultiplier * intersect).xyz;
	        }

	        float3 constructNormal(float3 v1, float3 v2, float3 v3) {
			    return normalize(cross(v2 - v1, v3 - v1));
			}

	        [maxvertexcount(3)]
	        void geo( triangle VertexAttributes input[3], uint pid : SV_PrimitiveID, inout TriangleStream<VertexAttributes> outStream ) {
				VertexAttributes t0 = (VertexAttributes)0;
				VertexAttributes t1 = (VertexAttributes)0;
				VertexAttributes t2 = (VertexAttributes)0;
				t0.vertex = input[0].vertex;
				t1.vertex = input[1].vertex;
				t2.vertex = input[2].vertex;
				t0.vertex.xyz += calculatePositionOffset(input[0]);
				t1.vertex.xyz += calculatePositionOffset(input[1]);
				t2.vertex.xyz += calculatePositionOffset(input[2]);

				t0.normal = constructNormal(mul(unity_ObjectToWorld,t0.vertex), mul(unity_ObjectToWorld,t1.vertex), mul(unity_ObjectToWorld,t2.vertex));
				t1.normal = t0.normal;
				t2.normal = t0.normal;

				t0.vertex = UnityObjectToClipPos(t0.vertex);
				t1.vertex = UnityObjectToClipPos(t1.vertex);
				t2.vertex = UnityObjectToClipPos(t2.vertex);

				outStream.Append(t0);
			    outStream.Append(t1);
			    outStream.Append(t2);
			    outStream.RestartStrip();
			}
	        VertexAttributes vert (VertexAttributes v) {
	            return v;
	        }
	        float4 frag(VertexAttributes i) : Color {
	            return float4((i.normal * 0.5 + 0.5).xyz,1);
	        }
	        ENDCG
	    }
    }
    FallBack "Diffuse"
}
