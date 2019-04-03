// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/DiffusePixelLevelShader"
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
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldNormal = mul(v.normal, (float3x3) unity_WorldToObject);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 diffuse = _LightColor0 * _Diffuse * saturate(dot(worldNormal, worldLight));
				fixed3 color = ambient + diffuse;
				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
}
