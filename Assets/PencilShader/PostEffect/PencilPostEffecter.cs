using System;
using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;
using Random = UnityEngine.Random;

[ExecuteInEditMode]
public class PencilPostEffecter : MonoBehaviour
{
    [SerializeField] private Material _material;

    [Range(1, 30)] public int _fps = 30;
    [SerializeField] Animator _animator;

    [SerializeField] bool ifFlip = true;
    [SerializeField] bool reverse = false;
    [SerializeField] float begin = 0;
    float _flip;
    private Texture2D _dataTex1;
    private Texture2D _dataTex2;

    private Vector2 sourceWH = new Vector2(0, 0);

    float _thresholdTime;

    float _skippedTime = 0f;

    bool changed = false;
    private bool tex1 = true;


    public void InitializeThresholdTime()
    {
        _thresholdTime = 1f / _fps;
    }

    public void ChangeColored(bool isColored)
    {
        _material.SetFloat("_Color", isColored ? 1 : 0);
    }

    private void OnValidate()
    {
        InitializeThresholdTime();
    }

    void Start()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;

        GetComponent<Camera>().depthTextureMode = DepthTextureMode.DepthNormals;
        _animator.enabled = false;
        InitializeThresholdTime();
        _material.SetFloat("_Flip", 1);
    }

    void Update()
    {
        _skippedTime += Time.deltaTime;

        if (_skippedTime >= _thresholdTime)
        {
            _animator.Update(_skippedTime);
            changed = true;
            _skippedTime = 0f;
        }

        if (ifFlip)
        {
            float x = _skippedTime / _thresholdTime;
            if (reverse)
            {
                _flip = -(-(Mathf.Cos(Mathf.PI * x) - 1) / 2) * (1 - begin) - begin;
            }
            else
            {
                _flip = (-(Mathf.Cos(Mathf.PI * x) - 1) / 2) * (1 - begin) + begin;
            }

            _material.SetFloat("_Flip", _flip);
        }


    }

    private void OnRenderImage(RenderTexture source, RenderTexture dest)
    {
        if (_material == null)
        {
            Graphics.Blit(source, dest);
            return;
        }

        var renderTexture = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);


        if (Math.Abs(sourceWH.x - source.width) > 10 || Math.Abs(sourceWH.y - source.height) > 10)
        {
            _dataTex1 = new Texture2D(source.width, source.height, TextureFormat.RGB24, false);
            _dataTex1.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
            _dataTex1.Apply();
            _dataTex2 = new Texture2D(source.width, source.height, TextureFormat.RGB24, false);
            _dataTex2.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
            _dataTex2.Apply();
            sourceWH.x = source.width;
            sourceWH.y = source.height;
        }

        if (reverse)
        {

            if (tex1)
            {
                //Graphics.Blit(source, dest);

                if (changed)
                {
                    _dataTex2.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
                    _dataTex2.Apply();
                    changed = false;
                    tex1 = !tex1;
                }
                float f = _material.GetFloat("_Flip");
                _material.SetFloat("_Flip", 1);
                Graphics.Blit(source, renderTexture, _material);
                _material.SetFloat("_Flip", f);
                _material.SetTexture("_BeforeTex", renderTexture);
                Graphics.Blit(_dataTex1, dest, _material);
            }
            else
            {

                if (changed)
                {
                    _dataTex1.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
                    _dataTex1.Apply();
                    changed = false;
                    tex1 = !tex1;
                }
                float f = _material.GetFloat("_Flip");
                _material.SetFloat("_Flip", 1);
                Graphics.Blit(source, renderTexture, _material);
                _material.SetFloat("_Flip", f);
                _material.SetTexture("_BeforeTex", renderTexture);
                Graphics.Blit(_dataTex2, dest, _material);
            }
        }
        else
        {
            float f = _material.GetFloat("_Flip");
            _material.SetFloat("_Flip", 1);
            Graphics.Blit(source, renderTexture, _material);
            if (changed)
            {
                if (tex1)
                {
                    _material.SetTexture("_BeforeTex", _dataTex1);
                    _dataTex2.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
                    _dataTex2.Apply();
                }
                else
                {
                    _material.SetTexture("_BeforeTex", _dataTex2);
                    _dataTex1.ReadPixels(new Rect(0, 0, source.width, source.height), 0, 0);
                    _dataTex1.Apply();
                }

                changed = false;
                tex1 = !tex1;
            }
            _material.SetFloat("_Flip", f);
            Graphics.Blit(source, dest, _material);
        }

        RenderTexture.ReleaseTemporary(renderTexture);


    }
}
