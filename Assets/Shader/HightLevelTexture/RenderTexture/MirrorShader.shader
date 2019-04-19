Shader "ShaderLearn/MirrorShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" }
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			sampler2D _MainTex;
			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			
			
			v2f vert (a2v v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.uv.x = 1 - o.uv.x;//在水平方向上 翻转渲染纹理，这是因为镜子里显示的图像是左右相反的
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				return tex2D(_MainTex,i.uv);
			}
			ENDCG
		}
	}
}
