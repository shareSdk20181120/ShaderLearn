Shader "ShaderLearn/SingleTextureShader"
{
	Properties
	{
		_MainTex ("Main Texture", 2D) = "white" {}
		_Color("Color Tint",Color) = (1,1,1,1)
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8,256)) = 20
	}
	SubShader
	{	

		Pass
		{ 
			Tags{ "LightMode" = "ForwardBase" }//定义该pass在unity的光照流水线中的角色
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal:NORMAL;
				float2 uv : TEXCOORD0;//unity会将模型的第一组纹理坐标存储在该变量中
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;				
				float3 worldNormal:TEXCOORD1;
				float3 worldPos:TEXCOORD2;
			};

			sampler2D _MainTex;
			/*
			为纹理类型属性 声明一个float4变量，注意改名字不是任意起的，在unity中，使用 纹理名_ST 方式来声明某个纹理的属性，ST是scale和translation 的缩写。
			_MainTex_ST.xy存储的是缩放值，_MainTex_ST.zw存储的是偏移值.这些值可以在材质面板中调节
			*/
			float4 _MainTex_ST;			//
			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);//这个内建函数等于 o.uv = v.uv.xy*_MainTex_ST.xy + _MainTex_ST.zw;先对顶点纹理坐标进行缩放，然后再使用偏移属性对结果进行偏移
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldPos = normalize(i.worldPos);
				//计算漫反射光照
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb*_Color.rgb;//使用贴图采集漫反射颜色
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz *albedo;
				fixed3 diffuse = _LightColor0*albedo*max(0, dot(worldNormal, worldLightDir));
				//计算高光反射光照  Blinn-Phong光照模型
				fixed viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize((worldLightDir + viewDir));
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
	}

			Fallback "Specular"
}
