Shader "Hide/URPPencilShaderUtil"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "Queue" = "AlphaTest"
            "RenderType" = "AlphaTest"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
			Name "OUTLINE" 
            Cull Front

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            }; 
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CutOut;
            float _OutlineWidth;
            float4 _OutlineColor;
            bool _NormalOutline;

            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                if(_NormalOutline){
                    o.pos = TransformObjectToHClip(v.vertex+ v.normal*_OutlineWidth/50);
                }else{
                    float width = _OutlineWidth*0.02+1.0;
                    half4x4 scaleMatrix = half4x4(width, 0, 0, 0,
                                             0, width, 0, 0,
                                             0, 0, width, 0,
                                             0, 0, 0, 1);
                    v.vertex = mul(scaleMatrix, v.vertex);
                    o.pos = TransformObjectToHClip(v.vertex);
                }
                 
                
                o.uv =TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = half4(_OutlineColor.rgb,1);   

                if(tex2D(_MainTex, i.uv).a <=_CutOut){
                    discard;
                }
                
                return col;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            Cull Back
            ZTest LEqual
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            // Pragmas
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _CutOut;

            struct appdata
            {
                float4 pos: POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };


            v2f vert (appdata i)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(i);
                o.uv =TRANSFORM_TEX(i.texcoord, _MainTex);
                VertexPositionInputs vInput = GetVertexPositionInputs(i.pos.xyz);
                o.pos = vInput.positionCS;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                if(tex2D(_MainTex, i.uv).a <=_CutOut){
                    discard;
                }
                return 0;
            }
            ENDHLSL
        }
    }
}
