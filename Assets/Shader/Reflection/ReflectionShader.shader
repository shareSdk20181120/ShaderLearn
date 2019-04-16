Shader "ShaderLearn/ReflectionShader"
{
	Properties
	{
		_Color("Color Tine",Color)=(1,1,1,1)
		_ReflectColor("Reflection Color",Color)=(1,1,1,1)//用于控制反射颜色
		_ReflectAmount("Reflection Amont",Range(0,1))=1 //用于控制反射程度
		_Cubemap("Reflection Cubemap",Cube)="_Skybox"{}//用于模型反射的环境映射纹理
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" "Queue"="Geometry" }
		LOD 100

		Pass
		{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			fixed4 _Color;
			fixed4 _ReflectColor;
			fixed4 _ReflectAmount;
			samplerCUBE _Cubemap;


			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldViewDir : TEXCOORD0;
				float3 worldNormal:TEXCOORD1;
				float3 worldPos:TEXCOORD2;
				float3 worldRefle : TEXCOORD3;
				SHADOW_COORDS(4)

			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefle = reflect(-o.worldViewDir, o.worldNormal);
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 diffuse = _LightColor0.rgb*_Color.rgb*max(0, dot(worldNormal, worldLightDir));
				fixed3 reflection = texCUBE(_Cubemap, i.worldRefle).rgb*_ReflectColor.rgb;
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount)*atten;

				return fixed4(color,1);
			}
			ENDCG
		}
	}
		Fallback "Reflective/VertexLit"
}
