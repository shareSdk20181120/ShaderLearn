Shader "ShaderLearn/AlpahBlendZWriteShader"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_AlphaScale("Alpha Scale",Range(0,1)) = 1//控制整体的透明度
	}
	SubShader
	{
		//RenderType这个标签可以让unity把这个shader归入到提前定义好的数组（Transparent组）中，用来指明该shader是一个透明度混合的shader
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }//通常使用透明度混合的shader都应该包含这三个标签
		Pass//这里加pass，为了把模型的深度信息写入缓冲中，从而踢出模型自身遮挡的片元
		{

			ZWrite On
			ColorMask 0//ColorMask 用于设置颜色通道的写掩码。他的语义：ColorMask RGB | A | 0 |其他任何RGBA的组合。当ColorMask设置为0时，意味着该pass不会输出任何颜色，
		}
		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }//定义该pass在unity的光照流水线中的角色
			ZWrite Off //透明度混合需要关闭深度写入功能
			Blend SrcAlpha OneMinusSrcAlpha //设置混合状态 使用同样的混合因子来混合RGB通道和A通道，混合等式使用的操作都是加操作。BlendOp BlendOperation命令

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
			fixed _AlphaScale;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target//这里的代码和透明度测试差不多，移除透明度测试代码（clip(_AlphaTest)）,并设置了返回值中的透明通道
			{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed4 texColor = tex2D(_MainTex, i.uv);//获取纹素值
				fixed3 albedo = texColor.rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz *albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0, dot(worldNormal, worldLightDir));

				return fixed4(ambient + diffuse, texColor.a*_AlphaScale);//只有打开使用了Blend命令，设置的透明通道才有意义
			}
			ENDCG
		}
	}

		Fallback "Transparent/VertexLit"  //当上述的subShader不满足当前显卡时，使用这个内置的shader
}



