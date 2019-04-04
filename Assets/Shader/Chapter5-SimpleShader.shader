// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "ShaderLearn/Chapter5-SimpleShader"
{
	Properties{
		_Color("Color Tint",Color) = (1.0,1.0,1.0,1.0)//定义一个颜色拾取器
	}
		SubShader
	{

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;
			struct a2v 
			{

				float4 pos:POSITION;
				float3 normal:NORMAL;//取值范围（-1，1）
				float4 tex:TEXCOORD0;
			};

			struct v2f//顶点着色器和片段着色器之间通信的结构
			{
				float4 pos :SV_POSITION;//这个是必须包含的，否则渲染器无法得到裁剪空间的顶点坐标，也就无法将顶点渲染到屏幕上
				fixed3 color : COLOR0;
			};
			/*float4 vert (float4 v:POSITION):SV_POSITION
			{
				
				return mul(UNITY_MATRIX_MVP,v);
			}
			
			fixed4 frag () : SV_Target
			{
				
				return fixed4(0.0f,1.0f,1.0f,1.0f);
			}*/

			//UNITY会根据语义填充数据到a2v这个结构，这些数据是由MeshRender组件提供的

			v2f vert(a2v input)
			{
				v2f o;
			o.pos = UnityObjectToClipPos(input.pos);
			o.color = input.normal*0.5f + fixed3(0.5, 0.5, 0.5);//取值范围转换为0，1
			return o;
			}

			fixed4 frag(v2f i):SV_Target
			{

				return fixed4(i.color*_Color.rgb,1.0);//将插值得到的i.color显示到屏幕上
			}
			ENDCG
		}
	}
}
