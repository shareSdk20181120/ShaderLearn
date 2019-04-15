// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
/*
计算阴影的三剑客：SHADOW_COORDS,TRANSFER_SHADOW,SHADOW_ATTENUATION
使用内置函数计算光照衰减和阴影
*/
Shader "ShaderLearn/AttenuationAndShadowUseBuildInFunctionShader"
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

		Pass//base pass  计算平行光
		{
			Tags{"LightMode" = "ForwardBase"}	

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			struct appdata
			{
				float4 vertex : POSITION;//变量名必须是vertex
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;//这里必须是pos
				float3 worldNormal:TEXCOORD0;
				float3 worldPos:TEXCOORD1;
				//实际上声明一个名为_ShadowCoord的阴影纹理坐标变量
				SHADOW_COORDS(2)//1 添加一个内置宏  用于声明一个对阴影纹理采样的坐标，需要注意的是这个宏参数需要时下一个可用的插值寄存器的索引值。
			};

		
			
			v2f vert (appdata v)//顶点着色器的输入结构体变量名必须是v
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				TRANSFER_SHADOW(o);//2这个宏用于在顶点着色器中计算上面声明的阴影纹理坐标,并将其存入_ShadowCoord变量中。实际上也是将顶点坐标从模型空间变换到光源空间。注意保证定义大变量名和宏中一致。
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
			
				//计算阴影
				/* 使用下面的内置宏实现
				//fixed atten = 1.0; //衰减值
				//fixed shadow = SHADOW_ATTENUATION(i);//计算阴影值，使用_ShadowCoord对相关的纹理进行采样。 使用内部宏定义
				*/
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//atten内部自动定义，第二个参数是用于传递给上面的计算阴影值的宏，第三个参数用于计算光源空间下的坐标.这个宏 实现了衰减值和阴影的相乘
				return fixed4(ambient + (diffuse + specular)*atten, 1.0);
			}
			ENDCG
		}

		Pass//additonal pass  计算其他光源类型
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
					float4 pos : SV_POSITION;
					float3 worldNormal:TEXCOORD0;
					float3 worldPos:TEXCOORD1;
					SHADOW_COORDS(2)
				};



				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.worldNormal = UnityObjectToWorldNormal(v.normal);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					TRANSFER_SHADOW(O);
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
					//光照衰减
					/*  使用内部宏代替
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
					*/
					UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
					return fixed4(ambient + (diffuse + specular)*atten, 1.0);
				}

				ENDCG
			}
	}

	Fallback "Specular"//注意虽然这个shader里面没有写标签为ShadowCaster的pass，但是Fallback调用的Specular的内部回调VertexLit里面可以找到
}
