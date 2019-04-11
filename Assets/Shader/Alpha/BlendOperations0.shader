Shader "ShaderLearn/BlendOperations0"
{
	Properties
	{
		_Color("Color",Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_AlphaScale("Alpah Scale",Range(0,1)) = 1
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha ,One Zero
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 texColor = tex2D(_MainTex,i.uv);
				return fixed4(texColor.rgb*_Color.rgb,texColor.a*_AlphaScale);
			}
			ENDCG
		}
	}
}
