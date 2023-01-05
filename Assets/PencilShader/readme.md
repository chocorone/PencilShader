# デッサン風シェーダー  PencilShader Built-in版

## 内容物
- readme.md(これ)
- SketchEffectフォルダ
    - SketchShader
    - SketchShaderMultiLight
    - Sketch.cginc、Util.Shader(消さないでね)
    - Sampleフォルダ(各種サンプルが入ってます)
- PostSketchEffectフォルダ(有料版)
    - PostSketchShader
    - Sampleフォルダ(各種サンプルが入ってます)
        - Built-inSampleフォルダ
- Textureフォルダ

## 各シェーダーについて

- SketchShader

オブジェクトに適用するとデッサン風になる基本的なシェーダーです

- SketchShaderMultiLight

シーンに複数ライトがあるときにいい感じに明るさを加算してくれる方のシェーダーです。パラメーターなどはSketchShaderと同じです。

普通のSketchShaderと異なりライトの数だけ計算されるので、シーンによってはちょっと重いかも

- PostSketchShader(有料版のみ)

このシェーダーのマテリアルを適用したオブジェクトを通して見たものたちが手書き風になります


## 使い方について

こちらにパラメーターなどの設定方法を詳しく記載しています。

https://usagi-meteor.com/unityデッサン風シェーダー使い方/



## テクスチャについて

線テクスチャは妹(Twitter:@P5aftU)に描いてもらいました。


