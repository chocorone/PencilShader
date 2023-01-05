half4 calSketchShading(half4 grayScaleCol,int useStroke,int useGradation,half strokeDensity,sampler2D paperTex,sampler2D stroke1,sampler2D stroke2,float2 uv,float2 worldPos)
{
    if(!useStroke){
        grayScaleCol *= tex2D(paperTex, uv)*0.7;
        return grayScaleCol;
    }

    //全体に紙のテクスチャを適用
    half4  col = tex2D(paperTex, uv)*1.2;
    float black = grayScaleCol.r-0.15;

    float2 scrPos = worldPos.xy* strokeDensity;

    // //階調化なし
    if(useGradation){
        if( black <= 0.2f ){ 
            col *= tex2D(stroke1, scrPos)*black*4; 
        } 
        else if(black <= 0.8f){
            col *= tex2D(stroke2, scrPos)*black*2;
        }
    //階調化あり
    }else{
        if( black <= 0.1f ){
            col *= tex2D(stroke1, scrPos)*0.1;
        }
        else if( black <= 0.2f ){
            col *= tex2D(stroke1, scrPos)*0.3;
        }
        else if( black <= 0.3f ){ 
            col *= tex2D(stroke1, scrPos)*0.5; 
        } 
        else if( black <= 0.4f ){
            col *= tex2D(stroke2, scrPos)*0.4; 
        }
        else if(black <= 0.6f){
            col *= tex2D(stroke2, scrPos)*0.8;
        }
        else if(black <= 0.8f){
            col *= tex2D(stroke2, scrPos)*1.2;
        }
    }
    return col;
}