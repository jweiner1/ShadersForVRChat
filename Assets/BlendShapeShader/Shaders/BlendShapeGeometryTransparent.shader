Shader "Custom/BlendShapeGeometryTransparent" {
    Properties {
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Base Color", 2D) = "white" {}
        _GlossMapScale ("Gloss Map Scale", Range(0, 1)) = 0.5
        _SpecGlossMap ("Spec Gloss Map", 2D) = "white" {}
        _LightWrapping ("Light Wrapping", Range(0, 1)) = 1
        _Transmission ("Transmission", Range(0, 1)) = 0.5
        _LightWrapRamp ("LightWrapRamp", 2D) = "white" {}
        _BlendShapeMultiplier("Blend Shape Multiplier", Range(0, 100)) = 1
        _BlendShapeBackDistanceMultiplier("Blend Shape Back Distance", Range(0, 10)) = 5
        _BlendShapeForwardDistanceMultiplier("Blend Shape Forward Distance", Range(0, 10)) = 5
        _BlendShapeCameraActivationDistance("Blend Shape Camera Activation Distance", Range(0, 10)) = 5
        _Emission ("Emission", Range(0, 1)) = 0.1
        _SpecularMultiplier ("Specular Multiplier", Range(0, 1)) = 0.25
    }
    SubShader {
        Tags {
            "Queue"="Transparent-2" "RenderType"="Transparent"
        }
        LOD 200
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag
            #define UNITY_PASS_FORWARDBASE
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 4.0
            uniform float4 _Color;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
            uniform float _GlossMapScale;
            uniform sampler2D _SpecGlossMap; uniform float4 _SpecGlossMap_ST;
            uniform float _LightWrapping;
            uniform float _Transmission;
            uniform float _BlendShapeMultiplier;
            uniform sampler2D _LightWrapRamp; uniform float4 _LightWrapRamp_ST;
            uniform float _Emission;
            uniform float _SpecularMultiplier;
            #include "VertexIntersection.cginc"
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float3 texcoord1 : TEXCOORD1;
                float3 texcoord2 : TEXCOORD2;
                float3 texcoord3 : TEXCOORD3;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 uv1 : TEXCOORD1;
                float3 uv2 : TEXCOORD2;
                float3 uv3 : TEXCOORD3;
                float4 posWorld : TEXCOORD4;
                float3 normalDir : TEXCOORD5;
                float3 normalDirCalc : TEXCOORD6;
                float3 tangentDir : TEXCOORD7;
                float3 bitangentDir : TEXCOORD8;
                LIGHTING_COORDS(9,10)
                UNITY_FOG_COORDS(11)
                #if defined(LIGHTMAP_ON) || defined(UNITY_SHOULD_SAMPLE_SH)
                    float4 ambientOrLightmapUV : TEXCOORD12;
                #endif
                float intersect : FLOAT;
            };

            float3 constructNormal(float3 v1, float3 v2, float3 v3) {
			    return normalize(cross(v2 - v1, v3 - v1));
			}

	        [maxvertexcount(3)]
	        void geo( triangle VertexOutput input[3], uint pid : SV_PrimitiveID, inout TriangleStream<VertexOutput> outStream ) {
				VertexOutput t0 = input[0];
				VertexOutput t1 = input[1];
				VertexOutput t2 = input[2];

				t0.normalDirCalc = constructNormal(t0.posWorld, t1.posWorld, t2.posWorld);
				t1.normalDirCalc = t0.normalDirCalc;
				t2.normalDirCalc = t0.normalDirCalc;

				outStream.Append(t0);
			    outStream.Append(t1);
			    outStream.Append(t2);
			    outStream.RestartStrip();
			}

            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.uv2 = v.texcoord2;
                #ifdef LIGHTMAP_ON
                    o.ambientOrLightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                    o.ambientOrLightmapUV.zw = 0;
                #elif UNITY_SHOULD_SAMPLE_SH
                #endif
                #ifdef DYNAMICLIGHTMAP_ON
                    o.ambientOrLightmapUV.zw = v.texcoord2.xy * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
                #endif
                float cameraIntersection;
	            o.intersect = GetVertexIntersection(v.vertex, cameraIntersection);
				float3 deltaPosition = (v.texcoord1.x * normalize(v.normal)) + (v.texcoord1.y * normalize(v.tangent.xyz)) + (v.texcoord1.z * normalize(cross(v.normal,v.tangent.xyz)));
	            v.vertex.xyz += deltaPosition * (o.intersect+cameraIntersection) * _BlendShapeMultiplier;

	            o.normalDir = UnityObjectToWorldNormal(v.normal) + (float3)v.texcoord2 * (o.intersect+cameraIntersection);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz ) + (float3)v.texcoord3 * (o.intersect+cameraIntersection);
                if ( length(deltaPosition) < 0.000001 ) {
                	o.intersect = 0;
                }
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;

                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
                float3 normalLocal = _BumpMap_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals

                // Dither/Lerp the normals based on the intersection
                float intersect = i.intersect;
            	float remap = 1-abs(intersect * 2 - 1);
            	float random = fmod(123456*length(i.posWorld)*_Time[0],1)*2-1;
            	float3 dither = float3(0.05,0.05,0.05)*random*remap;
                normalDirection = normalize(lerp(normalDirection,i.normalDirCalc,remap)+dither);

                float3 viewReflectDirection = reflect( -viewDirection, normalDirection );
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                if( isnan(lightDirection.x) || isinf(lightDirection.x) || length(lightDirection) == 0 ) {
                    lightDirection = normalize(float3(1,1,1));
                }
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                float4 _SpecGlossMap_var = tex2D(_SpecGlossMap,TRANSFORM_TEX(i.uv0, _SpecGlossMap));
                float gloss = (_SpecGlossMap_var.r*_GlossMapScale);
                float perceptualRoughness = 1.0 - (_SpecGlossMap_var.r*_GlossMapScale);
                float roughness = perceptualRoughness * perceptualRoughness;
                float specPow = exp2( gloss * 10.0 + 1.0 );
/////// GI Data:
                UnityLight light;
                #ifdef LIGHTMAP_OFF
                    light.color = lightColor;
                    light.dir = lightDirection;
                    light.ndotl = LambertTerm (normalDirection, light.dir);
                #else
                    light.color = half3(0.f, 0.f, 0.f);
                    light.ndotl = 0.0f;
                    light.dir = half3(0.f, 0.f, 0.f);
                #endif
                UnityGIInput d;
                d.light = light;
                d.worldPos = i.posWorld.xyz;
                d.worldViewDir = viewDirection;
                d.atten = attenuation;
                #if defined(LIGHTMAP_ON) || defined(DYNAMICLIGHTMAP_ON)
                    d.ambient = 0;
                    d.lightmapUV = i.ambientOrLightmapUV;
                #else
                    d.ambient = i.ambientOrLightmapUV;
                #endif
                #if UNITY_SPECCUBE_BLENDING || UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMin[0] = unity_SpecCube0_BoxMin;
                    d.boxMin[1] = unity_SpecCube1_BoxMin;
                #endif
                #if UNITY_SPECCUBE_BOX_PROJECTION
                    d.boxMax[0] = unity_SpecCube0_BoxMax;
                    d.boxMax[1] = unity_SpecCube1_BoxMax;
                    d.probePosition[0] = unity_SpecCube0_ProbePosition;
                    d.probePosition[1] = unity_SpecCube1_ProbePosition;
                #endif
                d.probeHDR[0] = unity_SpecCube0_HDR;
                d.probeHDR[1] = unity_SpecCube1_HDR;
                Unity_GlossyEnvironmentData ugls_en_data;
                ugls_en_data.roughness = 1.0 - gloss;
                ugls_en_data.reflUVW = viewReflectDirection;
                UnityGI gi = UnityGlobalIllumination(d, 1, normalDirection, ugls_en_data );
                lightDirection = gi.light.dir;
                if( isnan(lightDirection.x) || isinf(lightDirection.x) || length(lightDirection) == 0 ) {
                    lightDirection = normalize(float3(1,1,1));
                }
                lightColor = gi.light.color;
////// Specular:
                float NdotL = saturate(dot( normalDirection, lightDirection ));
                float LdotH = saturate(dot(lightDirection, halfDirection));
                float3 specularColor = (_SpecGlossMap_var.rgb*_SpecularMultiplier);
                float specularMonochrome;
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float3 node_6343 = (_MainTex_var.rgb*_Color.rgb);
                float3 diffuseColor = node_6343; // Need this for specular when using metallic
                diffuseColor = EnergyConservationBetweenDiffuseAndSpecular(diffuseColor, specularColor, specularMonochrome);
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = abs(dot( normalDirection, viewDirection ));
                float NdotH = saturate(dot( normalDirection, halfDirection ));
                float VdotH = saturate(dot( viewDirection, halfDirection ));
                float visTerm = SmithJointGGXVisibilityTerm( NdotL, NdotV, roughness );
                float normTerm = GGXTerm(NdotH, roughness);
                float specularPBL = (visTerm*normTerm) * UNITY_PI;
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularPBL = sqrt(max(1e-4h, specularPBL));
                #endif
                specularPBL = max(0, specularPBL * NdotL);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularPBL = 0.0;
                #endif
                half surfaceReduction;
                #ifdef UNITY_COLORSPACE_GAMMA
                    surfaceReduction = 1.0-0.28*roughness*perceptualRoughness;
                #else
                    surfaceReduction = 1.0/(roughness*roughness + 1.0);
                #endif
                specularPBL *= any(specularColor) ? 1.0 : 0.0;
                float3 directSpecular = attenColor*specularPBL*FresnelTerm(specularColor, LdotH);
                half grazingTerm = saturate( gloss + specularMonochrome );
                float3 indirectSpecular = (gi.indirect.specular);
                indirectSpecular *= FresnelLerp (specularColor, grazingTerm, NdotV);
                indirectSpecular *= surfaceReduction;
                float3 specular = (directSpecular + indirectSpecular);
/////// Diffuse:
                NdotL = dot( normalDirection, lightDirection );
                float2 node_9094 = (float2(dot(i.normalDir,lightDirection),0.5)*0.5+0.5);
                float4 _LightWrapRamp_var = tex2D(_LightWrapRamp,TRANSFORM_TEX(node_9094, _LightWrapRamp));
                float3 w = (_LightWrapping*_LightWrapRamp_var.rgb)*0.5; // Light wrapping
                float3 NdotLWrap = NdotL * ( 1.0 - w );
                float3 forwardLight = max(float3(0.0,0.0,0.0), NdotLWrap + w );
                float3 backLight = max(float3(0.0,0.0,0.0), -NdotLWrap + w ) * float3(_Transmission,_Transmission,_Transmission);
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotLWrap);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = ((forwardLight+backLight) + ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL)) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += gi.indirect.diffuse;
                diffuseColor *= 1-specularMonochrome;
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor;
////// Emissive:
                float3 emissive = (node_6343*_Emission);
/// Final Color:
                float3 finalColor = diffuse + specular + emissive;
                fixed4 finalRGBA = fixed4(finalColor,_MainTex_var.a*_Color.a);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
        Pass {
            Name "FORWARD_DELTA"
            Tags {
                "LightMode"="ForwardAdd"
            }
            Blend One One
            
            
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag
            #define UNITY_PASS_FORWARDADD
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 4.0
            uniform float4 _Color;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;
            uniform float _GlossMapScale;
            uniform sampler2D _SpecGlossMap; uniform float4 _SpecGlossMap_ST;
            uniform float _LightWrapping;
            uniform float _Transmission;
            uniform sampler2D _LightWrapRamp; uniform float4 _LightWrapRamp_ST;
            uniform float _Emission;
            uniform float _SpecularMultiplier;
            uniform float _BlendShapeMultiplier;
            #include "VertexIntersection.cginc"
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float3 texcoord1 : TEXCOORD1;
                float3 texcoord2 : TEXCOORD2;
                float3 texcoord3 : TEXCOORD3;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 uv1 : TEXCOORD1;
                float3 uv2 : TEXCOORD2;
                float3 uv3 : TEXCOORD3;
                float4 posWorld : TEXCOORD4;
                float3 normalDir : TEXCOORD5;
                float3 normalDirCalc : TEXCOORD6;
                float3 tangentDir : TEXCOORD7;
                float3 bitangentDir : TEXCOORD8;
                LIGHTING_COORDS(9,10)
                UNITY_FOG_COORDS(11)
                float intersect : FLOAT;
            };
            float3 constructNormal(float3 v1, float3 v2, float3 v3) {
			    return normalize(cross(v2 - v1, v3 - v1));
			}
            [maxvertexcount(3)]
	        void geo( triangle VertexOutput input[3], uint pid : SV_PrimitiveID, inout TriangleStream<VertexOutput> outStream ) {
				VertexOutput t0 = input[0];
				VertexOutput t1 = input[1];
				VertexOutput t2 = input[2];

				t0.normalDirCalc = constructNormal(t0.posWorld, t1.posWorld, t2.posWorld);
				t1.normalDirCalc = t0.normalDirCalc;
				t2.normalDirCalc = t0.normalDirCalc;

				outStream.Append(t0);
			    outStream.Append(t1);
			    outStream.Append(t2);
			    outStream.RestartStrip();
			}
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.uv2 = v.texcoord2;
                float3 lightColor = _LightColor0.rgb;

                // Blend shape intersection
                float cameraIntersect;
	            o.intersect = GetVertexIntersection(v.vertex, cameraIntersect);
	            float3 deltaPosition = (v.texcoord1.x * normalize(v.normal)) + (v.texcoord1.y * normalize(v.tangent.xyz)) + (v.texcoord1.z * normalize(cross(v.normal,v.tangent.xyz)));
	            v.vertex.xyz += deltaPosition * (o.intersect+cameraIntersect) * _BlendShapeMultiplier;
	            o.normalDir = UnityObjectToWorldNormal(v.normal) + (float3)v.texcoord2 * (o.intersect+cameraIntersect);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz ) + (float3)v.texcoord3 * (o.intersect+cameraIntersect);
                if ( length(deltaPosition) < 0.000001 ) {
                	o.intersect = 0;
                }
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);

                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
            float4 frag(VertexOutput i) : COLOR {
          

                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.uv0, _BumpMap)));
                float3 normalLocal = _BumpMap_var.rgb;
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // Perturbed normals

                // Dither/Lerp the normals based on the intersection
                float intersect = i.intersect;
            	float remap = 1-abs(intersect * 2 - 1);
            	float random = fmod(123456*length(i.posWorld)*_Time[0],1)*2-1;
            	float3 dither = float3(0.05,0.05,0.05)*random*remap;
                normalDirection = normalize(lerp(normalDirection,i.normalDirCalc,remap)+dither);

                float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
                float3 lightColor = _LightColor0.rgb;
                float3 halfDirection = normalize(viewDirection+lightDirection);
////// Lighting:
                float attenuation = LIGHT_ATTENUATION(i);
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
///////// Gloss:
                float4 _SpecGlossMap_var = tex2D(_SpecGlossMap,TRANSFORM_TEX(i.uv0, _SpecGlossMap));
                float gloss = (_SpecGlossMap_var.r*_GlossMapScale);
                float perceptualRoughness = 1.0 - (_SpecGlossMap_var.r*_GlossMapScale);
                float roughness = perceptualRoughness * perceptualRoughness;
                float specPow = exp2( gloss * 10.0 + 1.0 );
////// Specular:
                float NdotL = saturate(dot( normalDirection, lightDirection ));
                float LdotH = saturate(dot(lightDirection, halfDirection));
                float3 specularColor = (_SpecGlossMap_var.rgb*_SpecularMultiplier);
                float specularMonochrome;
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float3 node_6343 = (_MainTex_var.rgb*_Color.rgb);
                float3 diffuseColor = node_6343; // Need this for specular when using metallic
                diffuseColor = EnergyConservationBetweenDiffuseAndSpecular(diffuseColor, specularColor, specularMonochrome);
                specularMonochrome = 1.0-specularMonochrome;
                float NdotV = abs(dot( normalDirection, viewDirection ));
                float NdotH = saturate(dot( normalDirection, halfDirection ));
                float VdotH = saturate(dot( viewDirection, halfDirection ));
                float visTerm = SmithJointGGXVisibilityTerm( NdotL, NdotV, roughness );
                float normTerm = GGXTerm(NdotH, roughness);
                float specularPBL = (visTerm*normTerm) * UNITY_PI;
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularPBL = sqrt(max(1e-4h, specularPBL));
                #endif
                specularPBL = max(0, specularPBL * NdotL);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularPBL = 0.0;
                #endif
                specularPBL *= any(specularColor) ? 1.0 : 0.0;
                float3 directSpecular = attenColor*specularPBL*FresnelTerm(specularColor, LdotH);
                float3 specular = directSpecular;
/////// Diffuse:
                NdotL = dot( normalDirection, lightDirection );
                float2 node_9094 = (float2(dot(i.normalDir,lightDirection),0.5)*0.5+0.5);
                float4 _LightWrapRamp_var = tex2D(_LightWrapRamp,TRANSFORM_TEX(node_9094, _LightWrapRamp));
                float3 w = (_LightWrapping*_LightWrapRamp_var.rgb)*0.5; // Light wrapping
                float3 NdotLWrap = NdotL * ( 1.0 - w );
                float3 forwardLight = max(float3(0.0,0.0,0.0), NdotLWrap + w );
                float3 backLight = max(float3(0.0,0.0,0.0), -NdotLWrap + w ) * float3(_Transmission,_Transmission,_Transmission);
                NdotL = max(0.0,dot( normalDirection, lightDirection ));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1-gloss);
                float nlPow5 = Pow5(1-NdotLWrap);
                float nvPow5 = Pow5(1-NdotV);
                float3 directDiffuse = ((forwardLight+backLight) + ((1 +(fd90 - 1)*nlPow5) * (1 + (fd90 - 1)*nvPow5) * NdotL)) * attenColor;
                diffuseColor *= 1-specularMonochrome;
                float3 diffuse = directDiffuse * diffuseColor;
/// Final Color:
                float3 finalColor = diffuse + specular;
                fixed4 finalRGBA = fixed4(finalColor * 1,_MainTex_var.a*_Color.a);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
        Pass {
            Name "Meta"
            Tags {
                "LightMode"="Meta"
            }
            Cull Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define UNITY_PASS_META 1
            #define SHOULD_SAMPLE_SH ( defined (LIGHTMAP_OFF) && defined(DYNAMICLIGHTMAP_OFF) )
            #define _GLOSSYENV 1
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "UnityPBSLighting.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "UnityMetaPass.cginc"
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
            #pragma multi_compile DIRLIGHTMAP_OFF DIRLIGHTMAP_COMBINED DIRLIGHTMAP_SEPARATE
            #pragma multi_compile DYNAMICLIGHTMAP_OFF DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma only_renderers d3d9 d3d11 glcore gles 
            #pragma target 3.0
            uniform float4 _Color;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _GlossMapScale;
            uniform sampler2D _SpecGlossMap; uniform float4 _SpecGlossMap_ST;
            uniform float _Emission;
            uniform float _SpecularMultiplier;
            struct VertexInput {
                float4 vertex : POSITION;
                float2 texcoord0 : TEXCOORD0;
                float4 texcoord1 : TEXCOORD1;
                float4 texcoord2 : TEXCOORD2;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float3 uv1 : TEXCOORD1;
                float3 uv2 : TEXCOORD2;
                float4 posWorld : TEXCOORD3;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.uv1 = v.texcoord1;
                o.uv2 = v.texcoord2;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = UnityMetaVertexPosition(v.vertex, v.texcoord1.xy, v.texcoord2.xy, unity_LightmapST, unity_DynamicLightmapST );
                return o;
            }
            float4 frag(VertexOutput i) : SV_Target {
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                UnityMetaInput o;
                UNITY_INITIALIZE_OUTPUT( UnityMetaInput, o );
                
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(i.uv0, _MainTex));
                float3 node_6343 = (_MainTex_var.rgb*_Color.rgb);
                o.Emission = (node_6343*_Emission);
                
                float3 diffColor = node_6343;
                float4 _SpecGlossMap_var = tex2D(_SpecGlossMap,TRANSFORM_TEX(i.uv0, _SpecGlossMap));
                float3 specColor = (_SpecGlossMap_var.rgb*_SpecularMultiplier);
                float specularMonochrome = max(max(specColor.r, specColor.g),specColor.b);
                diffColor *= (1.0-specularMonochrome);
                float roughness = 1.0 - (_SpecGlossMap_var.r*_GlossMapScale);
                o.Albedo = diffColor + specColor * roughness * roughness * 0.5;
                
                return UnityMetaFragment( o );
            }
            ENDCG
        }
    }
    FallBack "Standard"
    CustomEditor "ShaderForgeMaterialInspector"
}
