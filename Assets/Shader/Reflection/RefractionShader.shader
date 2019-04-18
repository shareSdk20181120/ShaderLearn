﻿
/*
顶点折射方向计算  o.worldRefra=refract(-normalize(o.worldViewDir),normalize(o.worldNormal),_RefractRatio);
片元 折射纹理采样 fixed3 sampler= texCUBE(_Cubemap,o.worldRefra).rgb;
	 折射值	fixed3 refractColor= sampler*_RefractColor.rgb;
漫反射和折射混合 lerp(_diffuse,refractColor,_RefractAmont);
*/
Shader "ShaderLearn/RefractionShader"
{
	Properties
	{

		_Color("Color",Color) = (1,1,1,1)
		_RefractColor("Refraction Color",Color) = (1,1,1,1)
		_RefractAmont("Refraction Amont",Range(0,1)) = 1//混合learp
		_RefractRatio("Refraction Ratie",Range(0.1,1)) = 0.5//折射率比值
		_Cubemap("Cubemap",Cube)="_Skybox"{}
	}
	SubShader
	{
		Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			fixed4 _Color;
			fixed4 _RefractColor;
			fixed _RefractAmont;
			fixed _RefractRatio;
			samplerCUBE _Cubemap;


			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldPos:TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefra : TEXCOORD3;
				SHADOW_COORDS(4)

			};


			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefra = refract(-normalize( o.worldViewDir), normalize(o.worldNormal),_RefractRatio);//使用内部函数获得世界空间下折射方向，第一个参数和二个参数必须是归一化的。
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;		//环境光			
				fixed3 diffuse = _LightColor0.rgb*_Color.rgb*max(0, dot(worldNormal, worldLightDir));		//漫反射		
				fixed3 refraction = texCUBE(_Cubemap, i.worldRefra).rgb*_RefractColor.rgb;//折射  对立方体纹理采样需要使用texCUBE函数，注意这里我们并没有对反射信息进行归一化，因为我们仅作为方向传递的
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//光照衰减和阴影
				fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmont)*atten;//_RefractAmont用来混合漫反射和折射颜色

				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
		FallBack "Reflective/VertexLit"
}
