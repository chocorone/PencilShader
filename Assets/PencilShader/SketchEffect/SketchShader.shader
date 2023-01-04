Shader "PencilShader/SketchShader"
{
    Properties
    {
        _MainTex ("MainTexture", 2D) = "white" {}
        _Color ("Diffuse Color", Color) = (1, 1, 1, 1)

		_OutlineWidth ("Outline", Range(0, 1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        [Toggle]_NormalOutline("Outline by normal", Float) = 1

		_StrokeDensity ("Stroke Density", Range(1, 10)) = 5//線の密度
        _BrightNess ("BrightNess", Range(0.5, 20)) = 1//影を明るく
        [Toggle] _Shadow("Shadow", Float) = 1
        [Toggle] _ConsiderNormal("Consider dot(Normal*Light)", Float) = 1
        _CutOut ("CutOut", Range(0, 1)) = 0.1//くり抜くアルファ値の上限
        [Toggle] _UseGradation("Use Gradation", Float) = 0//階調化をなくす
        [Toggle] _UseStroke("Use Stroke", Float) = 1//線を表示する
        _PaperTex ("PaperTexture", 2D) = "white" {}
        _Stroke1 ("Stroke1", 2D) = "white" {}
		_Stroke2 ("Stroke2 ", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        {
            "Queue" = "AlphaTest"
            "RenderType" = "AlphaTest"
        }      

        UsePass "Hide/PencilShaderUtil/OUTLINE"
        
        Pass
        {
            Name "BASE"
            Tags
            {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap novertexlight
            #include "UnityLightingCommon.cginc"
            #include "Lighting.cginc" 
            #include "AutoLight.cginc"
            #include "Sketch.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            sampler2D _PaperTex;
            float4 _PaperTex_ST;
            sampler2D _Stroke1;
            sampler2D _Stroke2;
            float _StrokeDensity;
            float  _BrightNess;
            bool _UseGradation;
            bool _UseStroke;
            bool _Shadow;
            bool _ConsiderNormal;
            float _CutOut;

            struct appdata {
                float4 vertexOS : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            }; 

            struct v2f {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float2 worldPos : TEXCOORD1;
                half3 worldNormal:TEXCOORD2;
                SHADOW_COORDS(3)
            };


            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertexOS);
                o.worldPos=  ComputeScreenPos(o.pos).xy;
                
                o.uv =v.texcoord;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o)
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {   
                if(tex2D(_MainTex, i.uv).a <=_CutOut){
                    discard;
                }

                half4  col = tex2D(_MainTex, i.uv);
                col *= half4(_Color.rgb,1);

                //色を白黒に変換
                col.rgb = dot(col.rgb, half3(0.3, 0.59, 0.11));

                //影を考慮
                if(_Shadow){
                    half4 shadow = SHADOW_ATTENUATION(i);
                    half NdotL = saturate(dot(i.worldNormal, _WorldSpaceLightPos0.xyz));
                    half4 diff = NdotL * _LightColor0;
                    col *= diff * shadow;
                }

                col.g = col.r;
                col.b = col.r;
                
                //法線を考慮
                if(_ConsiderNormal){
                    col.rgb = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz)*col.rgb);
                }

                //明るさ補正
                col += 0.1;
                col *= 3;
                col *= _BrightNess;

                half4 col2 = calSketchShading(col,_UseStroke,_UseGradation,_StrokeDensity,_PaperTex,_Stroke1,_Stroke2,i.uv,i.worldPos);
                
                return col2;
            }
            ENDCG
        }

        UsePass "Hide/PencilShaderUtil/ShadowCaster"
    }
}