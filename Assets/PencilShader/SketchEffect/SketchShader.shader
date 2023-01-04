Shader "PencilShader/SketchShader"
{
    Properties
    {
        _MainTex ("MainTexture", 2D) = "white" {}
        _Color ("Diffuse Color", Color) = (1, 1, 1, 1)

		_OutlineWidth ("Outline", Range(0, 1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_StrokeDensity ("Stroke Density", Range(1, 10)) = 5//線の密度
        _BrightNess ("BrightNess", Range(0.5, 20)) = 1//影を明るく
        [Toggle] _Shadow("Shadow", Float) = 1
        [Toggle] _ConsiderNormal("Consider dot(Normal*Light)", Float) = 1
        [Toggle] _Apply_Transparency("Apply Transparency", Float) = 0//MainTexのアルファでくり抜くか
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
        LOD 100        

        CGINCLUDE
            #include "UnityCG.cginc" 
            sampler2D _MainTex;
            float4 _MainTex_ST;
            bool _Apply_Transparency;
            float _CutOut;
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

                o.pos = UnityObjectToClipPos(v.vertex+ v.normal*_OutlineWidth/50); 
                
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
            bool _Shadow;
            bool _ConsiderNormal;

            v2f vert (appdata v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos=  ComputeScreenPos(o.pos).xy;
                
                o.uv =v.texcoord;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                TRANSFER_SHADOW(o)
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {   
                if(tex2D(_MainTex, i.uv).a <=_CutOut){
                    discard;
                }

                fixed4  col = tex2D(_MainTex, i.uv);
                col *= fixed4(_Color.rgb,1);

                //色を白黒に変換
                col.rgb = dot(col.rgb, fixed3(0.3, 0.59, 0.11));

                //影を考慮
                if(_Shadow){
                    fixed4 shadow = SHADOW_ATTENUATION(i);
                    half NdotL = saturate(dot(i.worldNormal, _WorldSpaceLightPos0.xyz));
                    fixed4 diff = NdotL * _LightColor0;
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

                if(!_UseStroke){
                    col *= tex2D(_PaperTex, i.uv)*0.7;
                    return col;
                }

                //全体に紙のテクスチャを適用
                fixed4  col2 = tex2D(_PaperTex, i.uv)*1.2;
                float black = col.r-0.15;

                fixed2 scrPos = i.worldPos.xy* _StrokeDensity;

                // //階調化なし
                if(_UseGradation){
                    if( col.r <= 0.2f ){ 
                        col2 *= tex2D(_Stroke1, scrPos)*black*4; 
                    } 
                    else if(col.r <= 0.8f){
                        col2 *= tex2D(_Stroke2, scrPos)*black*2;
                    }
                //階調化あり
                }else{
                    if( black <= 0.1f ){
                        col2 *= tex2D(_Stroke1, scrPos)*0.1;
                    }
                    else if( black <= 0.2f ){
                        col2 *= tex2D(_Stroke1, scrPos)*0.3;
                    }
                    else if( black <= 0.3f ){ 
                        col2 *= tex2D(_Stroke1, scrPos)*0.5; 
                    } 
                    else if( black <= 0.4f ){
                        col2 *= tex2D(_Stroke2, scrPos)*0.4; 
                    }
                    else if(black <= 0.6f){
                        col2 *= tex2D(_Stroke2, scrPos)*0.8;
                    }
                    else if(black <= 0.8f){
                        col2 *= tex2D(_Stroke2, scrPos)*1.2;
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