Shader "Hide/PencilShaderUtil"
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
        }
        LOD 100

        Pass
        {
			Name "OUTLINE" 
            Cull Front

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #include "UnityCG.cginc" 

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            }; 
            
            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            bool _Apply_Transparency;
            float _CutOut;

            float _OutlineWidth;
            float4 _OutlineColor;

            bool _NormalOutline;

            v2f vert (appdata v)
            {
                v2f o;

                if(_NormalOutline){
                    o.pos = UnityObjectToClipPos(v.vertex+ v.normal*_OutlineWidth/50);
                }else{
                    float width = _OutlineWidth*0.02+1.0;
                    half4x4 scaleMatrix = half4x4(width, 0, 0, 0,
                                             0, width, 0, 0,
                                             0, 0, width, 0,
                                             0, 0, 0, 1);
                    v.vertex = mul(scaleMatrix, v.vertex);
                    o.pos = UnityObjectToClipPos(v.vertex);
                }
                 
                
                o.uv =v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(_OutlineColor.rgb,1);   

                if(_Apply_Transparency) {
                    if(tex2D(_MainTex, i.uv).a <=_CutOut){
                        discard;
                    }
                }  
                return col;
            }
            ENDCG
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode"="ShadowCaster" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert (appdata v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
