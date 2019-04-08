Shader "ShaderLearn/NormalMapWorldSpaceShader"
{
	Properties
	{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap("Bump Map",2D) = "bump"{}
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8,256))=8
		_BumpScale("BumpScale",Float)=1
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
				float4 tangent:TANGENT;
				
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 TtoW0:TEXCOORD1;//由于寄存器最多存储float4类型，所以定义三个变量来存储切线空间到世界空间的变换矩阵。为充分理由寄存器，最有一个位置存储顶点的世界坐标
				float4 TtoW1:TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;
			float _BumpScale;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.vertex.xy*_MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.vertex.xy*_BumpMap_ST.xy + _BumpMap_ST.zw;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x,worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));//对法线采集和解码
				bump.xy *= _BumpScale;
				bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy)));
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				fixed3 albedo = tex2D(_MainTex, i.uv.xy) *_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0, dot(bump, lightDir));

				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed specular = _LightColor0.rgb * _Specular.rgb *pow(max(0, dot(bump, halfDir)), _Gloss);

				return fixed4(ambient + diffuse + specular, 1.0);
			}
			ENDCG
		}
	}
}
