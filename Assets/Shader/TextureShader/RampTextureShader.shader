
/*
常见用法：使用渐变纹理控制漫反射光照的结果
*/
Shader "ShaderLearn/RampTextureShader"
{
	Properties
	{
		_Color("Color",Color)=(1,1,1,1)//材质颜色
		_RampTex ("Ramp Tex", 2D) = "white" {}//渐变纹理  注意将渐变纹理的wrapMode设置为Clamp模式，以防止对纹理进行采样时由于浮点数精度而造成的问题
		_Specular("Specular",Color)=(1,1,1,1)//高光颜色
		_Gloss("Gloss",Range(8,256))=8//高光区域
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
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldNormal:TEXCOORD1;
				float4 worldPos:TEXCOORD2;
			};

			sampler2D _RampTex;
			float4 _RampTex_ST;
			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _RampTex);//使用内置宏 计算经过平铺和便宜后的纹理坐标
				o.worldPos = mul(unity_ObjectToWorld,v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir( i.worldPos));
				fixed3 worldNormal = normalize(i.worldNormal);
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//漫反射光
				fixed halfLambert = 0.5 *dot(worldNormal, worldLightDir) + 0.5;//半兰伯特模型 计算点积结果被映射在(0,1)之间，，由于精度问题，虽然理论上在【0，1】  但是有可能出现1.00001；故要把渐变纹理设为clamp模式
				fixed2 uv = fixed2(halfLambert, halfLambert);//构造一个纹理坐标，因为_RampTex是一个一维纹理，这里uv方向都是用了halftLamber
				fixed3 samperColor = tex2D(_RampTex, uv).rgb;				//fixed diffuseColor =  tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb *_Color.rgb;
				fixed3 diffuse = _LightColor0.rgb*samperColor*_Color.rgb;
				//计算高光
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				return fixed4(ambient+diffuse+specular,1);
			}
			ENDCG
		}
	}
	Fallback "Specular"
}
