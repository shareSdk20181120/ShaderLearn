// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//逐顶点着色光照 可以得到更光滑的光照效果
Shader "LearnShader/DiffuseVertexLevelShader"
{
	Properties
	{
		_Diffuse("Diffuse", Color) = (1,1,1,1)//控制漫反射颜色
	}
		SubShader
	{


		Pass
		{

			Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"  //需要该文件里面的变量 _LightColor0--入射光的强度和颜色

			fixed4 _Diffuse;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				fixed3 color : COLOR;
				
			};			
			//
			v2f vert (a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);//将顶点坐标从模型空间转化为裁剪空间
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//获取环境光
				float3x3 temp2 = (float3x3) unity_WorldToObject;
				float3 temp = mul(v.normal, temp2);
				fixed3 worldNormal = normalize(temp.xyz);//将法线量从模型空间转换为世界空间，最后归一化
				float3 temp3= _WorldSpaceLightPos0.xyz;
				fixed3 worldLight = normalize(temp3);//获取世界空间下 归一化的光照方向 这个是假设场景中只有一种光且是平行光
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));//漫反射公式==  入射光的强度和颜色 *漫反射属性 *（（法向量 和光照方向向量的点积）结果截取为（0，1））
				o.color = ambient + diffuse;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			
				return fixed4(i.color,1.0);
			}
			ENDCG
		}

		//Falllback "Diffuse"
	}

		
}
