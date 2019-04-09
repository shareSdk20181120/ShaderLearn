Shader "ShaderLearn/MaskTexture"
{
	Properties
	{
		_Color("Color",Color)=(1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}//主纹理
		_BumpMap("Normal Map",2D)="bump"{}//法线纹理
		_BumpScale("Bump Scale",Float)=1
		_SpecularMask("Specular Mask",2D)="white"{}//高光反射遮罩纹理
		_SpecularScale("Specular Scale",Float)=1//控制遮罩影响度系数
		_Specular("Specular",Color)=(1,1,1,1)
		_Gloss("Gloss",Range(8,256))=8
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
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 lightDir:TEXCOORD1;
				float3 viewDir:TEXCOORD2;
			};

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;//这个是主纹理、法线纹理、遮罩纹理共同使用的纹理属性变量，这样可以节省需要存储的纹理坐标数目，否则随着纹理数目增加，我们会很快会占满顶点着色器中可以使用的插值寄存器
			sampler2D _BumpMap;
			//float4 _BumpMap_ST;
			float _BumpScale;
			sampler2D _SpecularMask;
			//float4 _SpecularMask_ST;
			float _SpecularScale;
			fixed4 _Specular;
			float _Gloss;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
				//漫反射
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb*_Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				fixed3 diffuse = _LightColor0.rgb*albedo*max(0, dot(tangentNormal, tangentLightDir));
				//高光
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed specularMask = tex2D(_SpecularMask, i.uv).r*_SpecularScale;//获取遮罩值  由于这里使用的每个纹素的rgb分量都一样，我们选择使用r分量来计算掩码值
				fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * specularMask;


				return fixed4(ambient+diffuse+specular,1);
			}
			ENDCG
		}
	}

			Fallback "Specular"
}
