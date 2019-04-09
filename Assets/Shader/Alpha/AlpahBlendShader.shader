Shader "ShaderLearn/AlpahBlendShadeer"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_CutOff("Alpha CutOff",Range(0,1)) = 0.5//透明度测试时，使用的判断条件，小于改值时，片元舍弃。它的范围是[0,1],这是因为纹理像素的透明度就在此范围
	}
	SubShader
	{
		Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }//通常使用透明度测试的shader都应该包含这三个标签
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
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos:TEXCOORD1;
				float3 worldNormal:TEXCOORD2;
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _CutOff;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed4 texColor = tex2D(_MainTex, i.uv);//获取纹素值
				clip(texColor.a - _CutOff);//进行透明度测试 这个函数等价于 if((texColor.a-_CutOff)<0) discard;

				fixed3 albedo = texColor.rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz *albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0, dot(worldNormal, worldLightDir));

				return fixed4(ambient + diffuse, 1);
			}
			ENDCG
		}
	}

	Fallback "Transparent/Cutout/VertexLit"  //当上述的subShader不满足当前显卡时，使用这个内置的shader
}
