// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "ShaderLearn/ForwardRenderingShader"
{
	Properties
	{
		_Diffuse("Diffuse",Color) = (1,1,1,1)
		_Specular("Specular",Color )= (1,1,1,1)
		_Gloss("Gloss",Range(8,256)) = 20
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass//base pass
		{
			Tags{"LightMode" = "ForwardBase"}	

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag			
			#include "Lighting.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldNormal:TEXCOORD0;
				float3 worldPos:TEXCOORD1;
			};

		
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//环境光
				//漫反射
				fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0, dot(worldNormal, worldLightDir));
				//自发光
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos).xyz;
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				fixed atten = 1.0;

				return fixed4(ambient + (diffuse + specular)*atten, 1.0);
			}
			ENDCG
		}

		Pass//additonal pass
			{
				Tags{ "LightMode" = "ForwardAdd" }
				Blend One One

				CGPROGRAM
				#pragma multi_compile_fwdadd
				#pragma vertex vert
				#pragma fragment frag			
				#include "Lighting.cginc"
				#include "AutoLight.cginc"

				fixed4 _Diffuse;
				fixed4 _Specular;
				float _Gloss;
				struct appdata
				{
					float4 vertex : POSITION;
					float3 normal:NORMAL;
				};

				struct v2f
				{
					float4 vertex : SV_POSITION;
					float3 worldNormal:TEXCOORD0;
					float3 worldPos:TEXCOORD1;
				};



				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					return o;
				}

				fixed4 frag(v2f i) : SV_Target
				{

					fixed3 worldNormal = normalize(i.worldNormal);
					#ifdef USING_DIRECTIONAL_LIGHT
						fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
					#else
						fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz-i.worldPos);
					#endif
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//环境光
					//漫反射
					fixed3 diffuse = _LightColor0.rgb*_Diffuse.rgb*max(0, dot(worldNormal, worldLightDir));
					//自发光
					fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos).xyz;
					fixed3 halfDir = normalize(worldLightDir + viewDir);
					fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0, dot(worldNormal, halfDir)), _Gloss);

					#ifdef USING_DIRECTIONAL_LIGHT					
						fixed atten = 1.0;
					#else
						#if defined (POINT)
							float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;//光照空间下，顶点位置
							fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;//从衰减纹理_LightTexture0(如果该光源使用了cookie，那么衰减纹理时_LightTextureB0)中，获取衰减值
						#elif defined (SPOT)
							float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
							fixed atten = (lightCoord.z > 0) *tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w*
							tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
						#else
							fixed atten = 1.0;
						#endif
					#endif				

					return fixed4(ambient + (diffuse + specular)*atten, 1.0);
				}

				ENDCG
			}
	}

	Fallback "Specular"//注意虽然这个shader里面没有写标签为ShadowCaster的pass，但是Fallback调用的Specular的内部回调VertexLit里面可以找到
}
