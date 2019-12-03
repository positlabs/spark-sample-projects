// Copyright 2004-present Facebook. All Rights Reserved.
//
// DO NOT MODIFY THIS FILE
//
// Any changes made to this file will make your effect be rejected from IG Creators

precision highp float;

#define PASS_MEAN_2x2  0
#define PASS_MEAN_8x8  1
#define PASS_GUIDED_BA  2
#define PASS_GUIDED_MEAN_BA  3
#define PASS_FINAL_COMPOSITE  4

#define MEAN_SAMPLE  8

uniform sampler2D inputImage;
uniform sampler2D inputMask;
uniform sampler2D sMean2x2;
uniform sampler2D sMean8x8;
uniform sampler2D sMean32x32;
uniform sampler2D sMean;
uniform sampler2D sBA;
uniform sampler2D sMeanBA;

uniform int passIndex;
uniform vec2 uInputImageSize;

// Skin-smoothing
uniform float uSmoothing;
uniform float uMinSmoothing;
uniform float uColorScreen;
uniform float uSCurve;

// // Tone-mapping
// uniform bool uUseLocalToneMap;
// uniform float uToneMapMidLuma;
// uniform float uToneMapDeltaExposureScale;
// uniform float uToneMapMinDeltaExposure;
// uniform float uToneMapMaxDeltaExposure;

varying highp vec2 v_uv;

vec3 phScreen(vec3 a, vec3 b) {
  return vec3(1.0) - (vec3(1.0) - a) * (vec3(1.0) - b);
}

vec3 phScreen(vec3 a, vec3 b, float opacity) {
  return mix(a, phScreen(a, b), opacity);
}

float luma(vec3 v) {
  return dot(v, vec3(0.2989, 0.5870, 0.1140));
}

vec4 boxFilter2x2(sampler2D samp, vec2 uv, vec2 duv) {
  vec4 color;

  color  = texture2D(samp, uv + vec2(-duv.x, -duv.y));
  color += texture2D(samp, uv + vec2( duv.x, -duv.y));
  color += texture2D(samp, uv + vec2(-duv.x,  duv.y));
  color += texture2D(samp, uv + vec2( duv.x,  duv.y));

  return 0.25 * color;
}

float logLuma(float lum) {
  return log(lum + 1.0);
}

vec3 logColor(vec3 col) {
  return log(col + 1.0);
}

float expLuma(float lum) {
  return exp(lum) - 1.0;
}

vec3 expColor(vec3 col) {
  return exp(col) - 1.0;
}

// result.x: center weighted average log luma
// result.y: minimum log luma
// result.y: maximum log luma
vec4 computeAverage(sampler2D samp, vec2 uv0, vec2 uv1, vec2 duv) {
  vec4 accum = vec4(
    0.0, // sum
    1.0, // min
    0.0, // max
    0.0); // unused

//  float areaWeight = duv.x * duv.y;
  float totalWeight = 0.0;
  vec2 texc;
  for (texc.y = uv0.y; texc.y < uv1.y; texc.y += duv.y) {
    for (texc.x = uv0.x; texc.x < uv1.x; texc.x += duv.x) {
      vec4 tex = texture2D(samp, texc);
      float lum = luma(tex.xyz);

      vec2 dir = texc - 0.5;
      float weight = 1.0 - 2.0*dot(dir, dir);
      weight *= weight;

      accum.x += weight * lum;
      totalWeight += weight;

      accum.y = min(accum.y, lum);
      accum.z = max(accum.z, lum);
    }
  }

  accum.x = logLuma(accum.x / totalWeight);
  accum.y = logLuma(accum.y);
  accum.z = logLuma(accum.z);

  return accum;
}

void main() {
  int kernelSize = 15;
  int smallKernelSize = ((kernelSize + 1) / MEAN_SAMPLE) + 1;
  float smallKernelSizeRcp = 1.0 / (float(smallKernelSize) * float(smallKernelSize));

  vec2 duv = float(MEAN_SAMPLE) / uInputImageSize;
  vec2 uv0 = v_uv - duv*0.5*float(smallKernelSize - 1);

  if (passIndex == PASS_MEAN_2x2) {
    // sMean2x2
    vec4 base;
    base.xyz = texture2D(inputImage, v_uv).xyz;
    base.w = luma(base.xyz);
    gl_FragColor = base;
  } else if (passIndex == PASS_MEAN_8x8) {
    // sMean8x8
    gl_FragColor = boxFilter2x2(sMean2x2, v_uv, 2.0/uInputImageSize);
  } else if (passIndex == PASS_GUIDED_BA) {
    vec4 meanIp = vec4(0.0);
    vec4 corrIp = vec4(0.0);

    for (int j = 0; j < smallKernelSize; j++) {
      for (int i = 0; i < smallKernelSize; i++) {
        vec2 texc = uv0 + duv * vec2(float(i), float(j));
#if MEAN_SAMPLE == 2
        vec4 tex = texture2D(sMean2x2, texc);
#elif MEAN_SAMPLE == 4
        vec4 tex = texture2D(sMean4x4, texc);
#elif MEAN_SAMPLE == 8
        vec4 tex = texture2D(sMean8x8, texc);
#endif
        meanIp += tex;
        corrIp += tex.w * tex;
      }
    }

    meanIp *= smallKernelSizeRcp;
    corrIp *= smallKernelSizeRcp;
    vec4 varIp = corrIp - meanIp.w * meanIp;

    float epsilon = uSmoothing;
    float epsilon2 = epsilon * epsilon;
    float a = varIp.w / (varIp.w + epsilon2);

    vec3 b = meanIp.xyz - a * meanIp.xyz;

    // sBA = (b, a)
    gl_FragColor = vec4(b, a);
  } else if (passIndex == PASS_GUIDED_MEAN_BA) {
    vec4 meanBA = vec4(0.0);

    for (int j = 0; j < smallKernelSize; j++) {
      for (int i = 0; i < smallKernelSize; i++) {
        vec2 texc = uv0 + duv * vec2(float(i), float(j));
        vec4 tex = texture2D(sBA, texc);
        meanBA += tex;
      }
    }

    meanBA *= smallKernelSizeRcp;

    // sMeanBA
    gl_FragColor = meanBA;
  } else if (passIndex == PASS_FINAL_COMPOSITE) {
    vec4 base = texture2D(inputImage, v_uv);
    //vec4 mask = texture2D(inputMask, v_uv);
    vec4 meanAB = texture2D(sMeanBA, v_uv);
    vec3 smoothed = meanAB.w * base.xyz + meanAB.xyz;

    vec3 smoothed2 = smoothed;

    // Uncomment to apply skin-smoothing to a masked area on the screen
    //base.xyz = mix(base.xyz, smoothed.xyz, max(uMinSmoothing, mask.b * mask.a));
    base.xyz = mix(base.xyz, smoothed.xyz, uMinSmoothing);
    // Increase brightness
    vec3 color = phScreen(base.xyz, base.xyz, uColorScreen);
    // S-curve to enhance contrast
    color = mix(color, smoothstep(0.0, 1.0, color), uSCurve);

    gl_FragColor = vec4(color, 1.0);
  }
}
