Shader "ShaderLearn/FresnelShader"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_FresnelScale("FresnelScale",Range(0,1))=0.5
		_Cubemap("Cubemap",Cube)="_Skybox"{}
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}
		LOD 100

		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			fixed _FresnelScale;
			samplerCUBE _Cubemap;
			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOORD0;
				fixed3 worldViewDir : TEXCOORD1;
				float3 worldPos:TEXCOORD2;
				fixed3 worldRefl : TEXCOORD3;
				SHADOW_COORDS(4)
			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;		//环境光			
				fixed3 diffuse = _LightColor0.rgb*_Color.rgb*max(0, dot(worldNormal, worldLightDir));		//漫反射

				fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb;//反射  对立方体纹理采样需要使用texCUBE函数，注意这里我们并没有对反射信息进行归一化，因为我们仅作为方向传递的
				fixed fresnel = _FresnelScale + (1 - _FresnelScale)*pow(1 - dot(worldViewDir, worldNormal), 5);//schlick菲涅耳反射近似公式
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//光照衰减和阴影
				fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel))*atten;

				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
}
