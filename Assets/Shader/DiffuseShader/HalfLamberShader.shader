Shader "ShaderLearn/HalfLamberShader"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1.0,1.0,1.0,1.0)
	}
	SubShader
	{

		Pass
	{
		Tags{ "LightMode" = "ForwardBase" }

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		#include "Lighting.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 normal : TEXCOORD0;
		};

		struct v2f
		{
			float3 worldNormal : TEXCOORD0;
			float4 vertex : SV_POSITION;
		};

		fixed4 _Diffuse;

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.worldNormal = mul(v.normal, (float3x3) unity_WorldToObject);

			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
			fixed3 worldNormal = normalize(i.worldNormal);
			fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
			//半兰伯特模型 没有使用saturate函数将点积的结果限制在（0，1），而是使用了0.5*点积+0.5的方式将结果限制在（0，1），这样背光面也可以看到光照效果
			fixed3 diffuse = _LightColor0 * _Diffuse * (0.5*dot(worldNormal, worldLight)+0.5);
			fixed3 color = ambient + diffuse;
			return fixed4(color,1.0);
		}
		ENDCG
	}
	}
		Fallback "Diffuse"
}
