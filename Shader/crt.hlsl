#pragma shaderfilter set _distort__description Distortion
#pragma shaderfilter set _distort__default 0.2
#pragma shaderfilter set _distort__max 1.0
#pragma shaderfilter set _distort__min 0.0
#pragma shaderfilter set _distort__slider true
uniform float _distort;

#pragma shaderfilter set _wideness__description Wideness
#pragma shaderfilter set _wideness__default 0.5
#pragma shaderfilter set _wideness__max 1.0
#pragma shaderfilter set _wideness__min 0.0
#pragma shaderfilter set _wideness__slider true
uniform float _wideness;

#pragma shaderfilter set _contrast__description Contrast
#pragma shaderfilter set _contrast__default 0.5
#pragma shaderfilter set _contrast__max 1.0
#pragma shaderfilter set _contrast__min 0.0
#pragma shaderfilter set _contrast__slider true
uniform float _contrast;

#pragma shaderfilter set _oozing__description Oozing
#pragma shaderfilter set _oozing__default 0.5
#pragma shaderfilter set _oozing__max 1.0
#pragma shaderfilter set _oozing__min 0.0
#pragma shaderfilter set _oozing__slider true
uniform float _oozing;

float rand(float2 uv)
{
    return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43756.5453);
}

float2 distort(float2 uv, float rate)
{
    uv -= 0.5;
    uv /= 1 - length(uv) * rate;
    uv += 0.5;
    return uv;
}

float4 gaussian_sample(float2 uv, float2 dx, float2 dy)
{
    float4 col  = image.Sample(builtin_texture_sampler, uv - dx - dy) * 1/16;
           col += image.Sample(builtin_texture_sampler, uv - dx) * 2/16;
           col += image.Sample(builtin_texture_sampler, uv - dx + dy) * 1/16;
           col += image.Sample(builtin_texture_sampler, uv - dy) * 2/16;
           col += image.Sample(builtin_texture_sampler, uv) * 4/16;
           col += image.Sample(builtin_texture_sampler, uv + dy) * 2/16;
           col += image.Sample(builtin_texture_sampler, uv + dx - dy) * 1/16;
           col += image.Sample(builtin_texture_sampler, uv + dx) * 2/16;
           col += image.Sample(builtin_texture_sampler, uv + dx + dy) * 1/16;
    return col;
}

float ease_in_out_cubic(float x)
{
    return x < 0.5
        ? 4 * x * x * x
        : 1 - pow(-2 * x + 2, 3) / 2; 
}

float crt_ease(float x, float base, float offset)
{
    float tmp = fmod(x + offset, 1);
    float xx = 1 - abs(tmp * 2 - 1);
    float ease = ease_in_out_cubic(xx);
    return ease * base + base * 0.8;
}

float4 render(float2 uv)
{
    uv.y = (uv.y - 0.5) * (_wideness*0.4 + 1) + 0.5;
    float2 in_uv = uv;
    uv = distort(uv, _distort*0.2);

    if(uv.x < 0 || 1 < uv.x || uv.y < 0 || 1 < uv.y ){
        return float4(0, 0, 0, 1);
    }
    
    float floor_x = fmod(in_uv.x * builtin_uv_size.x / 3, 1);
    float isR = floor_x <= 0.3;
    float isG = 0.3 < floor_x && floor_x <= 0.6;
    float isB = 0.6 < floor_x;

    float2 dx = float2(1 / builtin_uv_size.x, 0);
    float2 dy = float2(0, 1 / builtin_uv_size.y);

    uv += isR * -1 * dy;
    uv += isB * 1 * dy;

    float4 col = gaussian_sample(uv, dx, dy);
    col = pow(col, (1.6 + _contrast - 0.5));

    float floor_y = fmod(uv.y * builtin_uv_size.y / 6, 1);
    float ease_r = crt_ease(floor_y, col.r, rand(uv)* 0.1);
    float ease_g = crt_ease(floor_y, col.g, rand(uv)* 0.1);
    float ease_b = crt_ease(floor_y, col.b, rand(uv)* 0.1);

    col.r = (isR + (isG+isB)*_oozing*0.3) * ease_r;
    col.g = (isG + (isR+isB)*_oozing*0.3) * ease_g;
    col.b = (isB + (isR+isG)*_oozing*0.3) * ease_b;

    return col;
}