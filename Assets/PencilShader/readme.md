# デッサン風シェーダー  PencilShader

## 内容物
- readme.md(これ)
- SketchEffectフォルダ
    - SketchShader
    - URPSketchShader
    - Sketch.cginc、Util.Shader(消さないでね)
    - SketchShaderMultiLight
    - URPSketchShaderMultiLight
    - Sampleフォルダ(各種サンプルが入ってます)
        - Built-inSampleフォルダ
        - URPSampleフォルダ
- PostSketchEffectフォルダ(有料版)
    - PostSketchShader
    - URPPostSketchShader
    - Sampleフォルダ(各種サンプルが入ってます)
        - Built-inSampleフォルダ
        - URPSampleフォルダ
- Textureフォルダ

## 各シェーダーについて

- SketchShader

オブジェクトに適用するとデッサン風になる基本的なシェーダーです

- URPSketchShader

SketchShaderのURP対応版です

- SketchShaderMultiLight

シーンに複数ライトがあるときにいい感じに明るさを加算してくれる方のシェーダーです。パラメーターなどはSketchShaderと同じです。

普通のSketchShaderと異なりライトの数だけ計算されるので、シーンによってはちょっと重いかも

- URPSketchShaderMultiLight

SketchShaderMultiLightのURP版です

- PostSketchShader(有料版のみ)

このシェーダーのマテリアルを適用したオブジェクトを通して見たものたちが手書き風になります

- URPPostSketchShader(有料版のみ)

PostSketchShaderのURP版です

## 使い方について

こちらにパラメーターなどの設定方法を詳しく記載しています。

https://usagi-meteor.com/unityデッサン風シェーダー使い方/



## テクスチャについて

線テクスチャは妹(Twitter:@P5aftU)に描いてもらいました。


