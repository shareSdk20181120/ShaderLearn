Shader "ShaderLearn/NormalMapTangentSpaceShader"
{
	Properties
	{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		_BumpMap("Normal Map",2D) = "bump"{}//"bump"是unity内置的法线纹理，当没有提供任何纹理时，他就对应了模型自带的法线信息
		_BumpScale("Bump Scale",Float)=1//控制凹凸程度，当它为0 ，该法线纹理就不会对光照产生任何影响
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8,256))=8
	}
	SubShader
	{
		

		Pass
		{
			Tags{"LightMode"="ForwardBase"}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag			
			#include "Lighting.cginc"


			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float4 tangent: TANGENT;//注意切线是float4类型，因为我们需要他的w分量来决定切换空间的第三个坐标轴

			};

			struct v2f
			{
				float4 uv : TEXCOORD0;//由于我们有两种纹理 ，这里就定义了float4类型 来存储两个纹理坐标
				float4 vertex : SV_POSITION;
				float3 lightDir:TEXCOORD1;
				float3 viewDir:TEXCOORD2;
			};

			
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = v.uv.xy *_MainTex_ST.xy + _MainTex_ST.zw;//变换纹理坐标
				o.uv.zw = v.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;//变换法线纹理坐标
				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) *v.tangent.w;//计算出 组成切换空间的另一个坐标轴，使用w确定选择的副切线方向
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);//构造一个矩阵，实现模型空间到切线空间的转变
				//unity提供一个内置的宏TANGENT_SPACE_ROTATION(在UnityCG.cginc)来帮助我们计算得到rotation变换矩阵
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);//对法线纹理采样
				/* 
				基础知识普及：

					法线纹理中存储的是表面的法线方向，由于法线方向的分量范围在[-1,1],而像素的分量范围为[0,1].因此我们需要做一个映射：即 pixel=(normal+1)/2;
					这就要求，我们在shader中对法线纹理进行采样后，还需要对结果进行一次反映射的过程，以得到原先的法线方向。这个反映射的过程实际上就是上面映射映射函数的逆函数：normal=pixel*2-1;

				如果法线纹理  没有设置纹理类型为NormalMap类型，使用下面两行下计算方式，计算切线空间下的法线xy值。
					fixed3 tangentNormal;
					tangentNormal.xy = (packedNormal.xy * 2 - 1)*_BumpScale;
				否则使用如下：
					fixed3 tangentNormal=UnpackNormal(packedNormal);//normal=pixel*2-1;  pixel=(normal+1)/2;
					tangentNormal.xy*=_BumpScale;				
				*/	

				fixed3 tangentNormal = UnpackNormal(packedNormal);//normal=pixel*2-1;  pixel=(normal+1)/2;
				tangentNormal.xy *= _BumpScale;

				tangentNormal.z=sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex, i.uv.xy) *_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0, dot(tangentNormal, tangentLightDir));

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed specular = _LightColor0.rgb * _Specular.rgb *pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

				return fixed4(ambient+diffuse+specular,1.0);
			}
			ENDCG
		}
	}

			Fallback "Specular"
}
