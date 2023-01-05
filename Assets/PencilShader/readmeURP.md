# デッサン風シェーダー  PencilShader URP版

## 内容物
- readme.md(これ)
- SketchEffectフォルダ
    - URPSketchShader
    - URPSketchShaderMultiLight
    - Sketch.hlsl、URPUtil.Shader(消さないでね)
    - Sampleフォルダ(各種サンプルが入ってます)
- PostSketchEffectフォルダ(有料版)
    - URPPostSketchShader
    - Sampleフォルダ(各種サンプルが入ってます)
- Textureフォルダ


## 各シェーダーについて

- URPSketchShader

オブジェクトに適用するとデッサン風になる基本的なシェーダーです

- URPSketchShaderMultiLight

シーンに複数ライトがあるときにいい感じに明るさを加算してくれる方のシェーダーです。パラメーターなどはSketchShaderと同じです。

ただ明るくしすぎると影が消えて不自然な感じになるので、あまりシーンを明るくしすぎない方が良いと思います

- URPPostSketchShader(有料版のみ)

このシェーダーのマテリアルを適用したオブジェクトを通して見たものたちが手書き風になります



## 使い方について

こちらにパラメーターなどの設定方法を詳しく記載しています。

https://usagi-meteor.com/unityデッサン風シェーダー使い方/



## テクスチャについて

線テクスチャは妹(Twitter:@P5aftU)に描いてもらいました。


