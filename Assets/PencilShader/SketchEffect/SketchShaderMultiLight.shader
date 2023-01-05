Shader "PencilShader/SketchShader-MultiLight"
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
        _MultBrightNess ("Mult BrightNess", Range(0.1, 20)) = 0.5
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
        }

        UsePass "Hide/PencilShaderUtil/OUTLINE"

        UsePass "PencilShader/SketchShader/BASE"

        Pass {

            Tags { "LightMode"="ForwardAdd" }

            Blend One One
            ZWrite Off
            
            CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
           #pragma multi_compile_fwdadd

           #include "UnityCG.cginc"
           #include "AutoLight.cginc"
           #include "Sketch.cginc"

            struct appdata 
            {
                half4 vertex : POSITION;
                half3 normal : NORMAL;
                half2 texcoord : TEXCOORD0;
            };
            
            struct v2f
            {
                half4 pos : SV_POSITION;
                half2 uv : TEXCOORD0;
                half3 normal: TEXCOORD1;
                half3 ambient: TEXCOORD2;
                half3 worldPos: TEXCOORD3;
                LIGHTING_COORDS(4, 5)
                float2 worldUVPos : TEXCOORD6;
            };
            
            sampler2D _MainTex;
            half4 _MainTex_ST;
            half4 _LightColor0;

            sampler2D _PaperTex;
            float4 _PaperTex_ST;
            sampler2D _Stroke1;
            sampler2D _Stroke2;
            float _StrokeDensity;
            float  _BrightNess;
            bool _UseGradation;
            bool _UseStroke;
            bool _ConsiderNormal;
            float _CutOut;

            v2f vert (appdata v) 
            {
                v2f o = (v2f)0;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldUVPos=  ComputeScreenPos(o.pos).xy;
                
                return o;
            }

            half4 frag(v2f i) : COLOR 
            {
                if(tex2D(_MainTex, i.uv).a <=_CutOut){
                    discard;
                }

                half4 col = tex2D(_MainTex, i.uv);

                half3 lightDir;
                if (_WorldSpaceLightPos0.w > 0) {
                    lightDir = _WorldSpaceLightPos0.xyz - i.worldPos.xyz;
                } else {
                    lightDir = _WorldSpaceLightPos0.xyz;
                }
                lightDir = normalize(lightDir);

                UNITY_LIGHT_ATTENUATION(attenuation, i, i.normal);
                half3 diff = max(0, dot(i.normal, lightDir)) * _LightColor0 * attenuation;
                col.rgb *= diff;
                
                //色を白黒に変換
                col.rgb = dot(col.rgb, half3(0.3, 0.59, 0.11));
                col.rgb =min(col.r,0.4);
                col = calSketchShading(col,_UseStroke,_UseGradation,_StrokeDensity,_PaperTex,_Stroke1,_Stroke2,i.uv,i.worldUVPos);

                return col;
            }
            ENDCG
        }

        UsePass "Hide/PencilShaderUtil/ShadowCaster"
    }
}
