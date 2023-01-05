Shader "PencilShader/URPSketchShader"
{
    Properties
    {
        _MainTex ("MainTexture", 2D) = "white" {}
        _Color ("Diffuse Color", Color) = (1, 1, 1, 1)

		_OutlineWidth ("OutlineWidth", Range(0, 1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        [Toggle]_NormalOutline("Outline by normal", Float) = 1

		_StrokeDensity ("Stroke Density", Range(1, 10)) = 5
        _AddBrightNess ("Add BrightNess", Range(0, 1)) = 0
        _MultBrightNess ("Mult BrightNess", Range(0.1, 20)) = 1
        [Toggle] _Shadow("Shadow", Float) = 1
        _ShadowBrightness ("Shadow BrightNess", Range(0, 2)) = 1
        [Toggle] _ConsiderNormal("Consider dot(Normal*Light)", Float) = 1
        _CutOut ("CutOut", Range(0, 1)) = 0.1
        [Toggle] _UseGradation("Use Gradation", Float) = 0
        [Toggle] _UseStroke("Use Stroke", Float) = 1
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
            "RenderPipeline" = "UniversalPipeline"
        }      

        UsePass "Hide/URPPencilShaderUtil/OUTLINE"
        
        Pass
        {
            Name "BASE"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Sketch.hlsl"
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color;
            sampler2D _PaperTex;
            float4 _PaperTex_ST;
            sampler2D _Stroke1;
            sampler2D _Stroke2;
            float _StrokeDensity;
            float  _AddBrightNess;
            float _MultBrightNess;
            bool _UseGradation;
            bool _UseStroke;
            bool _Shadow;
            float _ShadowBrightness;
            bool _ConsiderNormal;
            float _CutOut;


            struct appdata {
                float4 vertexOS : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID                              
            }; 

            struct v2f {
                float4 pos : SV_POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float2 worldPos : TEXCOORD1;
                half3 worldNormal:TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = TransformObjectToHClip(v.vertexOS);
                o.worldPos=  ComputeScreenPos(o.pos).xy;
                
                o.uv =TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = normalize(mul(v.normal, (float3x3)UNITY_MATRIX_I_M));
                o.worldNormal = normalize(mul(v.normal, (float3x3)UNITY_MATRIX_I_M));
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertexOS.xyz);
                o.shadowCoord = GetShadowCoord(vertexInput);
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {   
                 UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                if(tex2D(_MainTex, i.uv).a <=_CutOut){
                    discard;
                }

                half4  col = tex2D(_MainTex, i.uv);
                col *= half4(_Color.rgb,1);

                //色を白黒に変換
                col.rgb = dot(col.rgb, half3(0.3, 0.59, 0.11));
                Light mainLight = GetMainLight(i.shadowCoord);
                float NdotL = saturate(dot(normalize(_MainLightPosition.xyz), i.normal));           
                      
                //影を考慮
                if(_Shadow){
                    col.rgb *= NdotL * _MainLightColor.rgb * mainLight.shadowAttenuation + (_ShadowBrightness-1);
                    col.g = col.r;
                    col.b = col.r;
                }
                
                //法線を考慮
                if(_ConsiderNormal){
                    col.rgb = saturate(NdotL*col.rgb);
                }

                //明るさ補正
                col += 0.1;
                col *= 3;
                col *= _MultBrightNess;
                col += _AddBrightNess;

                col = calSketchShading(col,_UseStroke,_UseGradation,_StrokeDensity,_PaperTex,_Stroke1,_Stroke2,i.uv,i.worldPos);
                
                return col;
            }
            ENDHLSL
        }

        UsePass "Hide/URPPencilShaderUtil/ShadowCaster"
        
    }
}