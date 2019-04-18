Shader "ShaderLearn/ReflectionShader"
{
	Properties
	{
		_Color("Color Tine",Color)=(1,1,1,1)
		_ReflectColor("Reflection Color",Color)=(1,1,1,1)//用于控制反射颜色
		_ReflectAmount("Reflection Amont",Range(0,1))=1 //用于控制反射程度
		_Cubemap("Reflection Cubemap",Cube)="_Skybox"{}//用于模型反射的环境映射纹理
	}
		SubShader
	{
		Tags { "RenderType" = "Opaque" "Queue"="Geometry" }
		Pass
		{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			fixed4 _Color;
			fixed4 _ReflectColor;
			fixed _ReflectAmount;
			samplerCUBE _Cubemap;


			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;				
				float3 worldPos:TEXCOORD0;			
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefle : TEXCOORD3;
				SHADOW_COORDS(4)

			};

			
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);
				o.worldRefle = reflect(-o.worldViewDir, o.worldNormal);//使用内部函数获得世界空间下反射方向，注意第一个参数为负的
				TRANSFER_SHADOW(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);			
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;		//环境光			
				fixed3 diffuse = _LightColor0.rgb*_Color.rgb*max(0, dot(worldNormal, worldLightDir));		//漫反射		
				fixed3 reflection = texCUBE(_Cubemap, i.worldRefle).rgb*_ReflectColor.rgb;//反射  对立方体纹理采样需要使用texCUBE函数，注意这里我们并没有对反射信息进行归一化，因为我们仅作为方向传递的
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//光照衰减和阴影
				fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount)*atten;

				return fixed4(color,1.0);
			}
			ENDCG
		}
	}
		FallBack "Reflective/VertexLit"
}
