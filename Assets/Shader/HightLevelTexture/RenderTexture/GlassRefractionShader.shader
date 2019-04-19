Shader "ShaderLearn/GlassRefractionShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}//玻璃的材质纹理
		_BumpMap("_BumpMap",2D)="bump"{}//玻璃的法线
		_Cubemap("Environment CubeMap",Cube)="_Skybox"{}//模拟反射的环境纹理
		_Distortion("Distortion",Range(0,100))=10//控制模拟折射时图像的扭曲程度
		_RefractAmount("RefractAmont",Range(0,1))=1.0//折射程度，0--只包括反射，1--只包括折射
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Transparent"}//看是矛盾 实在服务于不同的需求
		GrabPass{"_RefractionTex"} //定义一个抓取屏幕图像的pass，这个名字决定了抓取的图像存储在哪个纹理中，可省略声明该字符串，直接声明的话可以得到更高的性能
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			float _Distortion;
			fixed _RefractAmount;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float4 tangent:TANGENT;
			};

			struct v2f
			{				
				float4 pos : SV_POSITION;
				float4 scrPos:TEXCOORD0;
				float4 uv:TEXCOORD1;
				float4 TtoW0:TEXCOORD2;
				float4 TtoW1:TEXCOORD3;
				float4 TtoW2:TEXCOORD4;

			};

			
			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw=TRANSFORM_TEX(v.uv,_BumpMap);
				o.scrPos = ComputeGrabScreenPos(o.pos);
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;//
				o.TtoW0 = float4(worldTangent.x, worldNormal.x, worldBinormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldNormal.y, worldBinormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldNormal.z, worldBinormal.z, worldPos.z);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));//切换空间下的法向量
				float2 offset = bump.xy*_Distortion*_RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset*i.scrPos.z + i.scrPos.xy;
				//折射颜色
				fixed3 refraColor = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;//对抓取到的折射图片采样
				//环境光 反射--对立方体纹理采样tex2D(_Cubemap,reflDir).
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));//获取世界空间下的法向量
				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 reflColor = texCUBE(_Cubemap, reflDir).rgb*texColor.rgb;
				//反射和折射混合
				fixed3 finalColor = reflColor*(1 - _RefractAmount) + refraColor*_RefractAmount;

				return fixed4(finalColor,1.0);
			}
			ENDCG
		}
	}
}
