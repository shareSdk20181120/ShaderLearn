
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//对比高光逐顶点光照来说，逐像素可以得到更平滑的效果，这是因为逐顶点光照的高光部分计算是非线性的，而后插值过程是线性的，这样破坏了原有的非线性关系，就会出现比较大的视觉问题
Shader "ShaderLearn/SpecularPixelLevelShader"
{
	Properties
	{
		_Diffuse("Diffuse",Color) = (1,1,1,1)//漫反射颜色的属性
		_Specular("Specular",Color) = (1,1,1,1)//控制高光反射的颜色的属性
		_Gloss("Gloss",Range(8.0,256)) = 20//高光区域大小的属性
	}
		SubShader
	{

		Pass
		{
			Tags { "LightMode" = "ForwardBase" }//只有定义正确的LightMode，我们才能得到一些unity的内置光照变量，如：_LightColor0--入射光

			CGPROGRAM
			#pragma vertex vert  //使用#pragma命令告诉unity,我们定义的顶点着色器和片段着色器的名字
			#pragma fragment frag
			#include "Lighting.cginc" //为了使用里面的内置变量

			fixed4 _Diffuse;//fixed的取值范围是（-2，2） 一般用于定义颜色
			fixed4 _Specular;
			float _Gloss;
			struct appdata //输入结构
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				
			};

			struct v2f  //输出结构
			{				
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos:TEXCOORD1;
			};

			
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.worldPos = mul(v.vertex, unity_WorldToObject).xyz;

				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//环境光
				//计算漫反射
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));
				//计算高光反射
				fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));//计算反射方向  因为reflect要求光源指向交点处，这取反	
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);//观察方向--世界空间下，摄像机坐标位置减去顶点坐标
				fixed3 specular = _LightColor0.rgb *_Specular.rgb  * pow(saturate(dot(reflectDir, viewDir)),_Gloss);//高光计算公式=入射光颜色*高光属性*（反射方向和观察方向的点积的高光区域大小平方）
				fixed3 color = ambient + diffuse + specular;
				return fixed4(color,1);
			}
			ENDCG
		}
	}
	Fallback "Specular"
}
