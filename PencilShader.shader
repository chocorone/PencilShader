Shader "Custom/PencilShader"
{
    Properties
    {
        _MainTex ("MainTexture", 2D) = "white" {}
        _PaperTex ("PaperTexture", 2D) = "white" {}
        _Color ("Diffuse Color", Color) = (1, 1, 1, 1)
		_OutlineWidth ("Outline", Range(0, 1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_StrokeDensity ("Stroke Density", Range(1, 10)) = 5//線の密度
        _BrightNess ("BrightNess", Range(0.5, 20)) = 1//影を明るく
        [Toggle] _SelfShadow("Self Shadow", Float) = 1
        [Toggle] _ConsiderNormal("Consider dot(Normal*Light)", Float) = 1
        [Toggle] _Apply_Transparency("Apply Transparency", Float) = 0//MainTexのアルファでくり抜くか
        _CutOut ("CutOut", Range(0, 1)) = 0.1//くり抜くアルファ値の上限
        [Toggle] _UseGradation("Use Gradation", Float) = 0//階調化をなくす
        [Toggle] _UseStroke("Use Stroke", Float) = 1//線を表示する
        [Toggle] _Move("Move", Float) = 1
        _Frec ("Frec", Range(0, 1)) = 0.5
        _ShakeSize ("Shake Size", Range(0, 0.1)) = 0.015
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
        LOD 100        

        CGINCLUDE
            #include "UnityCG.cginc" 
            sampler2D _MainTex;
            float4 _MainTex_ST;
            bool _Move;
            float _Frec;
            bool _Apply_Transparency;
            float _CutOut;
            float _ShakeSize;
            float rand(float2 co) 
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }
        ENDCG

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

            float _OutlineWidth;
            float4 _OutlineColor;

            v2f vert (appdata v)
            {
                v2f o;
                if(_Move){
                    float time = floor(sin(_Time.x)*_Frec*200);
                    float r = rand(float2(time,time))*_ShakeSize;
                    o.pos = UnityObjectToClipPos(v.vertex+ v.normal*_OutlineWidth/50) +r ;
                }else{
                    o.pos = UnityObjectToClipPos(v.vertex+ v.normal*_OutlineWidth/50); 
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

            struct appdata {
                float4 vertex : POSITION;
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

            fixed4 _Color;
            sampler2D _PaperTex;
            float4 _PaperTex_ST;
            sampler2D _Stroke1;
            sampler2D _Stroke2;
            float _StrokeDensity;
            float  _BrightNess;
            bool _UseGradation;
            bool _UseStroke;
            bool _SelfShadow;
            bool _ConsiderNormal;

            v2f vert (appdata v)
            {
                v2f o;

                if(_Move){
                    float time = floor(sin(_Time.x)*_Frec*200);
                    float r = rand(float2(time,time))*_ShakeSize;
                    o.pos = UnityObjectToClipPos(v.vertex)+r ;
                    o.worldPos=  ComputeScreenPos(o.pos).xy + r;
                }else{
                    o.pos = UnityObjectToClipPos(v.vertex);
                    o.worldPos=  ComputeScreenPos(o.pos).xy;
                }
                o.uv =v.texcoord;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {   
                fixed4  col = tex2D(_MainTex, i.uv);
                col *= fixed4(_Color.rgb,1);

                if(_SelfShadow){
                    fixed4 shadow = SHADOW_ATTENUATION(i);
                    half NdotL = saturate(dot(i.worldNormal, _WorldSpaceLightPos0.xyz));
                    fixed4 diff = NdotL * _LightColor0;
                    col *= diff * shadow;
                }

                col *= _BrightNess;
                
                half nl = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz)*col.rgb);
                if(!_ConsiderNormal){
                    nl = col.rgb;
                }
                fixed4  col2 =tex2D(_PaperTex, i.uv)*1.1;
                fixed2 scrPos = i.worldPos.xy* _StrokeDensity;

                if(_UseGradation){
                    if( nl <= 0.2f ){ 
                        col2 *= tex2D(_Stroke1, scrPos)*nl*4; 
                    } 
                    else if(nl <= 0.7f){
                        col2 *= tex2D(_Stroke2, scrPos)*nl*2;
                    }
                }else{
                    if( nl <= 0.01f ){
                        col2 *= tex2D(_Stroke1, scrPos)*0.5;
                    }
                    else if( nl <= 0.1f ){
                        col2 *= tex2D(_Stroke1, scrPos)*0.7;
                    }
                    else if( nl <= 0.2f ){ 
                        col2 *= tex2D(_Stroke1, scrPos)*0.9; 
                    } 
                    else if( nl <= 0.3f ){
                        col2 *= tex2D(_Stroke2, scrPos)*0.8; 
                    }
                    else if(nl <= 0.4f){
                        col2 *= tex2D(_Stroke2, scrPos)*1;
                    }
                    else if(nl <= 0.5f){
                        col2 *= tex2D(_Stroke2, scrPos)*1.3;
                    }
                }
                
                if(!_UseStroke){
                    col2.rgb = dot(col.rgb, fixed3(0.3, 0.59, 0.11));
                }

                if(_Apply_Transparency) {
                    if(tex2D(_MainTex, i.uv).a <=_CutOut){
                        discard;
                    }
                }
                
                return col2;
            }
            ENDCG
        }

        Pass
        {
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
