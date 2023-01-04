Shader "Custom/PostHandWriting"
{
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _BeforeTex("Before Texture",2D)= "black" {}

        [Toggle] _Color("Color", float) = 1
        _OutlineColor ("Outline Color", Color) = (1, 1, 1, 1)
        _NormalThreshold("Normal Threshold", Range(0, 5)) = 1
        _NormalOutlineWidth("NormalWidth", Range(0, 10)) = 1
        _NormalMagnitude ("Normal Magnitude", Range(0, 10)) = 1
        _DepthThreshold("Depth Threshold", Range(0, 10)) = 1
        _DepthMagnitude("Depth Magnitude", Range(0, 10)) = 1
        _DepthOutlineWidth("DepthWidth", Range(0, 10)) = 1
        _ColorThreshold("ColorDepth Threshold", Range(0, 10)) = 1
        _ColorOutlineWidth("ColorWidth", Range(0, 10)) = 1
        _ColorMagnitude("Color Magnitude", Range(0, 10)) = 1


        _TexRotation("TexRotation", Range(0, 360)) = 45
        _PaperTex ("PaperTexture", 2D) = "white" {}
        _StrokeDensity ("Stroke Density", Range(1, 10)) = 5//線の密度
        _Stroke1 ("Stroke1", 2D) = "white" {}
		_Stroke2 ("Stroke2 ", 2D) = "white" {}

        _Flip("Flip",Range(-1, 1)) = 0
    }
    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off

        Tags { "Queue" = "AlphaTest+1"
            "RenderType"="Transparent" }

        Pass
        {
            CGPROGRAM
           #pragma vertex vert
           #pragma fragment frag
            
           #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };
            
            sampler2D _CameraDepthTexture;
            float4 _CameraDepthTexture_ST;
            float4 _CameraDepthTexture_TexelSize;
            sampler2D _CameraDepthNormalsTexture;
            float4 _CameraDepthNormalsTexture_TexelSize;

            float _NormalThreshold;
            float _NormalOutlineWidth;
            float _NormalMagnitude;

            float _DepthThreshold;
            float _DepthOutlineWidth;
            float _DepthMagnitude;

            float _ColorThreshold;
            float _ColorOutlineWidth;
            float _ColorMagnitude;

            float4 _OutlineColor;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            sampler2D _BeforeTex;
            float4 _BeforeTex_ST;

            float _StrokeDensity;
            float _TexRotation;
            sampler2D _PaperTex;
            sampler2D _Stroke1;
            sampler2D _Stroke2;
            float _r;

            bool _Color;

            float _Flip;

            float2 uv;
            
            
            void sampleDepthNormal(float2 uv, out float depth, out float3 normal)
            {
                float4 cdn = tex2D(_CameraDepthNormalsTexture, uv);
                DecodeDepthNormal(cdn, depth, normal);
                normal *= float3(1.0, 1.0, -1.0);
            }

            float calDepth(v2f i){
                float4 cdn = tex2D(_CameraDepthNormalsTexture, uv);
                float3 n = DecodeViewNormalStereo(cdn) * float3(1.0, 1.0, -1.0);

                float diffX = _CameraDepthTexture_TexelSize.x * _DepthOutlineWidth;
                float diffY = _CameraDepthTexture_TexelSize.y * _DepthOutlineWidth;
                float col00 = Linear01Depth(tex2D(_CameraDepthTexture, uv+ half2(-diffX, -diffY)).r);
                float col10 = Linear01Depth(tex2D(_CameraDepthTexture, uv+ half2(0, -diffY)).r);
                float col01 = Linear01Depth(tex2D(_CameraDepthTexture, uv+ half2(-diffX, 0)).r);
                float col11 = Linear01Depth(tex2D(_CameraDepthTexture, uv+ half2(0, 0)).r);
                return (col00 - col11) * (col00 - col11) + (col10 - col01) * (col10 - col01);
            }

            float3 calNormal(v2f i){
                float diffX = _CameraDepthNormalsTexture_TexelSize.x * _NormalOutlineWidth;
                float diffY = _CameraDepthNormalsTexture_TexelSize.y * _NormalOutlineWidth;
                float3 norm00, norm10, norm01, norm11;
                float depth00, depth10, depth01, depth11;
                sampleDepthNormal(uv+ float2(-diffX, -diffY), depth00, norm00);
                sampleDepthNormal(uv + float2(diffX, -diffY), depth10, norm10);
                sampleDepthNormal(uv+ float2(-diffX, diffY) , depth01, norm01);
                sampleDepthNormal(uv + float2(diffX, diffY), depth11, norm11);
                float3 diffNorm00_11 = norm00 - norm11;
                float3 diffNorm10_01 = norm10 - norm01;

                return diffNorm00_11 * diffNorm00_11 + diffNorm10_01 * diffNorm10_01;
            }

            float calColor(v2f i){
                float diffX = _MainTex_TexelSize.x * _ColorOutlineWidth;
                float diffY = _MainTex_TexelSize.y * _ColorOutlineWidth;
                float3 col00 = tex2D(_MainTex,uv+ half2(-diffX, -diffY));
                float3 col10 = tex2D(_MainTex, uv+ half2(0, -diffY));
                float3 col01 = tex2D(_MainTex, uv+ half2(-diffX, 0));
                float3 col11 = tex2D(_MainTex,uv+ half2(0, 0));
                return (col00 - col11) * (col00 - col11) + (col10 - col01) * (col10 - col01);
            }

            float3 rgb2hsv(float3 rgb)
            {
                float3 hsv;

                // RGBの三つの値で最大のもの
                float maxValue = max(rgb.r, max(rgb.g, rgb.b));
                // RGBの三つの値で最小のもの
                float minValue = min(rgb.r, min(rgb.g, rgb.b));
                // 最大値と最小値の差
                float delta = maxValue - minValue;
                
                // V（明度）
                // 一番強い色をV値にする
                hsv.z = maxValue;
                
                // S（彩度）
                // 最大値と最小値の差を正規化して求める
                if (maxValue != 0.0){
                    hsv.y = delta / maxValue;
                } else {
                    hsv.y = 0.0;
                }
                
                // H（色相）
                // RGBのうち最大値と最小値の差から求める
                if (hsv.y > 0.0){
                    if (rgb.r == maxValue) {
                        hsv.x = (rgb.g - rgb.b) / delta;
                    } else if (rgb.g == maxValue) {
                        hsv.x = 2 + (rgb.b - rgb.r) / delta;
                    } else {
                        hsv.x = 4 + (rgb.r - rgb.g) / delta;
                    }
                    hsv.x /= 6.0;
                    if (hsv.x < 0)
                    {
                        hsv.x += 1.0;
                    }
                }
                
                return hsv;
            }

            float3 hsv2rgb(float3 hsv)
            {
                float3 rgb;

                if (hsv.y == 0){
                    // S（彩度）が0と等しいならば無色もしくは灰色
                    rgb.r = rgb.g = rgb.b = hsv.z;
                } else {
                    // 色環のH（色相）の位置とS（彩度）、V（明度）からRGB値を算出する
                    hsv.x *= 6.0;
                    float i = floor (hsv.x);
                    float f = hsv.x - i;
                    float aa = hsv.z * (1 - hsv.y);
                    float bb = hsv.z * (1 - (hsv.y * f));
                    float cc = hsv.z * (1 - (hsv.y * (1 - f)));
                    if( i < 1 ) {
                        rgb.r = hsv.z;
                        rgb.g = cc;
                        rgb.b = aa;
                    } else if( i < 2 ) {
                        rgb.r = bb;
                        rgb.g = hsv.z;
                        rgb.b = aa;
                    } else if( i < 3 ) {
                        rgb.r = aa;
                        rgb.g = hsv.z;
                        rgb.b = cc;
                    } else if( i < 4 ) {
                        rgb.r = aa;
                        rgb.g = bb;
                        rgb.b = hsv.z;
                    } else if( i < 5 ) {
                        rgb.r = cc;
                        rgb.g = aa;
                        rgb.b = hsv.z;
                    } else {
                        rgb.r = hsv.z;
                        rgb.g = aa;
                        rgb.b = bb;
                    }
                }
                return rgb;
            }

            fixed4 calPixelColor(float4 col){

                float3 hsv = rgb2hsv(col.rgb);

                hsv.x=floor(hsv.x*360/20)*20/360;
                hsv.y=floor(hsv.y*255/20)*20/255;
                hsv.z=floor(hsv.z*255/20)*20/255;

                return float4(hsv2rgb(hsv),1);
            }

            float l2(float x)
			{
				return 1 - _Flip + 0.1 * cos(x * 1.5);
			}

			float l1(float y)
			{
				return _Flip + 0.1 * sin(y * 3);
			}

			float l0(float x)
			{
				return x - _Flip;
			}

            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _CameraDepthTexture);
                
                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                uv = i.uv ;

                if (i.uv.x <= l1(i.uv.y) || i.uv.y >= l2(i.uv.x)){
                    half a=(_Flip-1)*0.09;
                    half angleCos = cos(a);
                    half angleSin = sin(a);

                    half2x2 rotateMatrix = half2x2(angleCos, -angleSin, angleSin, angleCos);
                    
                    
                    // 中心を起点にUVを回転させる
                    uv = mul(uv, rotateMatrix);
                    uv.x-=a;
                    uv.y+=a;
                }

                 uv+=_r;

                fixed4 col = tex2D(_MainTex, uv);

                half nl = dot(col.rgb, fixed3(0.3, 0.59, 0.11));

                half angleCos = cos(_TexRotation);
                half angleSin = sin(_TexRotation);
                half2x2 rotateMatrix = half2x2(angleCos, -angleSin, angleSin, angleCos);
                half2 paperuv = i.uv - 0.5;
                paperuv = mul(paperuv, rotateMatrix) + 0.5+_r;
                fixed2 scrPos =(paperuv)* _StrokeDensity;
                col =tex2D(_PaperTex, i.uv)*1.1;

                if(_Color){
                    if( nl <= 0.2f ){
                        col *= tex2D(_Stroke1, scrPos)*0.4;
                    }
                    else if( nl <= 0.3f ){
                        col *= tex2D(_Stroke1,  scrPos)*0.7;
                    }
                    else if( nl  <= 0.4f ){ 
                        col *= tex2D(_Stroke1,  scrPos)*0.8; 
                    } 
                    else if( nl  <= 0.6f ){
                        col *= tex2D(_Stroke2,  scrPos)*0.7; 
                    }else{
                        col *= tex2D(_Stroke2,  scrPos)*0.7;
                    }
                    float3 hsv= rgb2hsv(tex2D(_MainTex, uv));

                    if(hsv.z>0.2){
                        if(col.r<=0.6){
                            col=calPixelColor(tex2D(_MainTex, uv))*min(col.r*4,1);
                            hsv.y=min(col.r*4.5,hsv.y)*1.1;
                            hsv.z=min(hsv.z*max(col.r*2,0.8)*1.4,hsv.z);

                        }else {
                            col=calPixelColor(tex2D(_MainTex, uv))*min(col.r*4,1);
                            hsv.y=min(col.r*4.5,hsv.y)*0.6;
                            if(hsv.z>0.7){
                                hsv.z=min(hsv.z*max(col.r*2,0.8)*1.4,hsv.z);
                            }else{
                                hsv.z=min(hsv.z*max(col.r*2,0.8)*1.4,hsv.z)*1.3;  
                            }
                             
                        } 
                        col.rgb = hsv2rgb(hsv);                        
                    }

                    hsv= rgb2hsv(col.xyz);
                    if(hsv.z>0.99&&hsv.y<0.12){
                        col *=tex2D(_PaperTex, i.uv)*1.05;
                    }
                }else{
                    if( nl <= 0.01f ){
                        col *= tex2D(_Stroke1, scrPos)*0.5;
                    }
                    else if( nl <= 0.1f ){
                        col *= tex2D(_Stroke1, scrPos)*0.7;
                    }
                    else if( nl <= 0.3f ){ 
                        col *= tex2D(_Stroke1, scrPos)*0.9; 
                    } 
                    else if( nl <= 0.5f ){
                        col *= tex2D(_Stroke2, scrPos)*0.8; 
                    }
                    else if(nl <= 0.65f){
                        col *= tex2D(_Stroke2, scrPos)*0.9;
                    }
                    else if(nl <= 0.8f){
                        col *= tex2D(_Stroke2, scrPos)*1.4;
                    }
                }



                if(calDepth(i)*10000*_DepthMagnitude>_DepthThreshold){
                    col = _OutlineColor;
                }

                if(length(calNormal(i))*_NormalMagnitude>_NormalThreshold){
                    col = _OutlineColor;
                }

                if(length(calColor(i))*_ColorMagnitude>_ColorThreshold){
                     col = _OutlineColor;
                }

                if((i.uv.y<(i.uv.x-_Flip+1*(1-_Flip)))){
                    col *= min(float4(0.99, 0.99, 0.99, 1),(i.uv.y-i.uv.x)+2*(_Flip));
                   
                }


				//範囲内ならば暗い色に
				if (i.uv.x > l1(i.uv.y) && i.uv.y < l2(i.uv.x)){
					col = float4(0.5, 0.5, 0.5, 1)*tex2D(_PaperTex, i.uv);
                }                    
                

				//L0より右の描画を無視
				float l0_y = l0(i.uv.x);
				if(i.uv.y - l0_y<=0){
                    col= tex2D(_BeforeTex, i.uv);
                    if(i.uv.y - l0_y>-0.15){
                        col*=min((0.1+(-i.uv.y + l0_y)*6),0.99);
                    }
                }
                
                return col;
            }
            ENDCG
        }
    }
}
