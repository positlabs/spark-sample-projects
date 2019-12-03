// Copyright 2004-present Facebook. All Rights Reserved.
//
// DO NOT MODIFY THIS FILE
//
// Any changes made to this file will make your effect be rejected from IG Creators

#line 0
#define PI 3.1415
#define LUMA vec3(0.2989, 0.5870, 0.1140)
precision highp float;

varying vec2 v_TexCoords;
varying vec3 v_ReflectionVec;

uniform sampler2D uFaceTracker0;
uniform sampler2D uMakeupColorReplaceMask;
uniform sampler2D uMakeupAmbientOcclusion;
uniform sampler2D uMakeupMaterial;
uniform sampler2D uEnvironmentReflection;

uniform vec4 uMakeupConstantColor1;
uniform vec4 uMakeupConstantColor2;
uniform vec4 uMakeupConstantColor3;

uniform float uMakeupAlpha;             // [0, 1]
uniform float uMakeupLightness;         // [0, 1]
uniform float uMakeupSaturation;        // [0, 1]
uniform float uMakeupReflectiveness;    // [0, 1]

uniform float uLightSensitive;
uniform float uGlossMultipler;
uniform float uGlossThreshold;

vec2 equirectMap(vec3 dir) {
  dir = normalize(dir);
  vec2 latLong = vec2(-atan(dir.z, dir.x) + PI, acos(dir.y));
  return latLong / vec2(2.0 * PI, PI);
}

float luma(vec3 color) {
  // Gamma luma
  return dot(color, LUMA);
}

float luma(vec4 color) {
  return luma(color.rgb);
}

vec3 linear2gamma(in vec3 v) {
  return sqrt(v);
}
vec4 linear2gamma(in vec4 v) {
  return vec4(linear2gamma(v.rgb), v.a);
}
vec3 gamma2linear(in vec3 v) {
  return v * v;
}
vec4 gamma2linear(in vec4 v) {
  return vec4(gamma2linear(v.rgb), v.a);
}

vec3 xyz2rgb(in vec3 c) {
  const mat3 mat = mat3( 3.2404542, -0.9692660,  0.0556434,
                        -1.5371585,  1.8760108, -0.2040259,
                        -0.4985314,  0.0415560,  1.0572252);

  vec3 v = mat * (c / 100.0);
  vec3 c0 = (1.055 * linear2gamma(v)) - 0.055;
  vec3 c1 = 12.92 * v;
  vec3 r = mix(c0, c1, step(v, vec3(0.0031308)));
  return r;
}

vec4 xyz2rgb(in vec4 xyz) {
    return vec4(xyz2rgb(xyz.rgb), xyz.a);
}

vec3 xyz2lab(in vec3 c) {
  vec3 n = c / vec3(95.047, 100.0, 108.883);
  vec3 c0 = pow(n, vec3(1.0 / 3.0));
  vec3 c1 = (7.787 * n) + (16.0 / 116.0);
  vec3 v = mix(c0, c1, step(n, vec3(0.008856)));
  return vec3((116.0 * v.y) - 16.0,
              500.0 * (v.x - v.y),
              200.0 * (v.y - v.z));
}

vec4 xyz2lab(in vec4 c) {
  return vec4(xyz2lab(c.xyz), c.w);
}

vec3 rgb2xyz(in vec3 c) {
  const mat3 mat = mat3(0.4124564, 0.2126729, 0.0193339,
                        0.3575761, 0.7151522, 0.1191920,
                        0.1804375, 0.0721750, 0.9503041);

  vec3 c0 = gamma2linear((c + 0.055) / 1.055);
  vec3 c1 = c / 12.92;
  vec3 tmp = mix(c0, c1, step(c, vec3(0.04045)));
  return mat * (100.0 * tmp);
}

vec4 rgb2xyz(in vec4 rgb) {
    return vec4(rgb2xyz(rgb.rgb),rgb.a);
}

vec3 lab2xyz(in vec3 c) {
  vec3 f;
  f.y = (c.x + 16.0) / 116.0;
  f.x = c.y / 500.0 + f.y;
  f.z = f.y - c.z / 200.0;
  vec3 c0 = f * f * f;
  vec3 c1 = (f - 16.0 / 116.0) / 7.787;
  return vec3(95.047, 100.000, 108.883) * mix(c0, c1, step(f, vec3(0.206897)));
}

vec4 lab2xyz(in vec4 c) {
  return vec4(lab2xyz(c.xyz), c.w);
}

vec3 lab2rgb( in vec3 lab ) {
  return xyz2rgb( lab2xyz( lab ) );
}

vec3 rgb2lab( in vec3 rgb ) {
  return xyz2lab( rgb2xyz( rgb ) );
}

vec3 phMultiply(vec3 a, vec3 b, float opacity) {
  return mix(a, a * b, opacity);
}

vec3 phContrastBrightness(vec3 a, float contrast, float brightness) {
  return (a - vec3(0.5)) * (1.0 + contrast) + vec3(0.5) + vec3(brightness);
}

vec3 phSaturation(vec3 a, vec3 saturation) {
  vec3 dotLuma = vec3(dot(a, LUMA));
  return a + saturation * (a - dotLuma);
}

vec3 phContrastBrightnessSaturation(vec3 a, float contrast, float brightness, vec3 saturation) {
  return phSaturation(phContrastBrightness(a, contrast, brightness), saturation);
}

float phOverlay(float a, float b) {
  return (a < 0.5)? 2.0 * a * b : 1.0 - 2.0 * (1.0 - a) * (1.0 - b);
}

vec3 phOverlay(vec3 a, vec3 b) {
  return vec3(phOverlay(a.x, b.x), phOverlay(a.y, b.y), phOverlay(a.z, b.z));
}

vec3 phOverlay(vec3 a, vec3 b, float opacity) {
  return mix(a, phOverlay(a, b), opacity);
}

vec3 phScreen(vec3 a, vec3 b) {
  return vec3(1.0) - (vec3(1.0) - a) * (vec3(1.0) - b);
}

vec3 phScreen(vec3 a, vec3 b, float opacity) {
  return mix(a, phScreen(a, b), opacity);
}

float phCustomGamma(float color, float gamma){
    return pow(color, 1.0 / gamma);
}

vec3 phCustomGamma(vec3 color, float gamma){
    return pow(color, vec3(1.0 / gamma));
}

float phLevels(float a, float minLevel, float maxLevel) {
  float delta = max(0.0, a - minLevel);
  float range = maxLevel - minLevel;
  return min(delta / range, 1.0);
}

float phLevels(float a, float minLevel, float maxLevel, float gamma) {
  return phCustomGamma(phLevels(a, minLevel, maxLevel), gamma);
}

vec3 phLevels(vec3 a, float minLevel, float maxLevel) {
  vec3 levelDelta = max(vec3(0.0), a - vec3(minLevel));
  vec3 levelRange = vec3(maxLevel) - vec3(minLevel);
  return min((levelDelta / levelRange), vec3(1.0));
}

vec3 phLevels(vec3 a, float minLevel, float maxLevel, float gamma) {
  return phCustomGamma(phLevels(a, minLevel, maxLevel), gamma);
}

float getLipCenterOcclusion(vec2 uv) {
  float uLipRadialOcclusion = 16.0;

  // Get a point in the center of the mouth and radial occlude around it
  vec2 uvMouthCenter = vec2(0.5, 0.696);
  vec2 uvDelta = (uv - uvMouthCenter) * vec2(uLipRadialOcclusion * 0.2, uLipRadialOcclusion);
  float val = 1.0 - length(uvDelta);
  val = max(0.0, val);
  val = pow(val, 6.0);
  val = 1.0 - val;
  val *= val;
  val = min(val, 1.0);

  return val;
}

vec3 getReflectionColor() {
  vec2 uv = equirectMap(v_ReflectionVec);
  return texture2D(uEnvironmentReflection, uv).xyz;
}

void main() {
  vec2 uv = v_TexCoords;
  // ARStudio doesn't support REPEAT sampling, so implement it in shader
  vec2 uvRepeat = fract(uv * vec2(6.0, 6.0));

  vec4 faceColor = texture2D(uFaceTracker0, uv);
  vec4 makeupMask = texture2D(uMakeupColorReplaceMask, uv);
  vec4 makeupMaterial = texture2D(uMakeupMaterial, uv);
  vec4 makeupAO_rgb = texture2D(uMakeupAmbientOcclusion, uv);

  // Makeup combine
  float makeupColor1Alpha = makeupMask.r;
  float makeupColor2Alpha = makeupMask.g;
  float makeupColor3Alpha = makeupMask.b;
  float makeupColorTotalAlpha = makeupColor1Alpha + makeupColor2Alpha + makeupColor3Alpha;
  float makeupAO = makeupAO_rgb.r;

  // Early exit
  float finalAlpha = min(1.0, makeupColorTotalAlpha) * uMakeupAlpha;
  if (finalAlpha <= 0.01) {
    discard;
  }

  // Luma
  float smoothLuma = smoothstep(0.0, 1.3, 0.3 + 0.7 * luma(faceColor.xyz));

  // Handle makeup color
  // ----------------------------------------------------------------------
  float invMakeupColorAlpha = 1.0 / max(0.001, makeupColorTotalAlpha);
  float makeupCombine1 = makeupColor1Alpha * invMakeupColorAlpha;
  float makeupCombine2 = makeupColor2Alpha * invMakeupColorAlpha;
  float makeupCombine3 = makeupColor3Alpha * invMakeupColorAlpha;
  vec3 makeupColor1 = makeupCombine1 * uMakeupConstantColor1.xyz;
  vec3 makeupColor2 = makeupCombine2 * uMakeupConstantColor2.xyz;
  vec3 makeupColor3 = makeupCombine3 * uMakeupConstantColor3.xyz;
  vec3 baseMakeupColor = makeupColor1 + makeupColor2 + makeupColor3;
  baseMakeupColor = phContrastBrightnessSaturation(baseMakeupColor, 0.0, 0.6 * uMakeupLightness, vec3(uMakeupSaturation));

  // Highlight 1 - Can be cut if optimization is needed
  vec3 block2;
  block2 = vec3(phLevels(smoothLuma, 80.0/255.0, 210.0/255.0, 1.0));
  baseMakeupColor = phScreen(baseMakeupColor, block2, 0.5);

  // Highlight 2
  vec3 block3;
  block3 = vec3(phLevels(smoothLuma, 56.0/255.0, 133.0/255.0, 1.0));
  baseMakeupColor = phMultiply(baseMakeupColor, block3, 0.5);

  // Ambient Occlusion
  vec3 makeupColor = baseMakeupColor * makeupAO;

  float glossAlpha = makeupMaterial.r * makeupMaterial.a;
  float glossPower = makeupMaterial.g * makeupMaterial.a;
  float shineAlpha = makeupMaterial.b * makeupMaterial.a;
  float shinePower = shineAlpha * pow(smoothLuma, 5.0 * (1.1 - uLightSensitive));

  vec3 makeupLab = rgb2lab(makeupColor.rgb);
  // ---- Begin: LAB Color Space
  // Shine - LAB, L range is [0, 100]
  makeupLab.x = pow(makeupLab.x * 0.5, 1.0 + shinePower * 5.0) + makeupLab.x * 0.5;
  // Gloss - LAB, L range is [0, 100]
  makeupLab.x = smoothstep(0.0, 100.0, makeupLab.x) * 100.0;
  // Smoother highlight
  float thresholdApply = smoothstep(uGlossThreshold - 0.01, uGlossThreshold + 0.01, smoothLuma);
  thresholdApply = max(0.1, thresholdApply);
  makeupLab.x += 500.0 * thresholdApply * glossAlpha * uGlossMultipler * pow(smoothLuma, 1.0 + (5.0 - 5.0 * glossPower));
  // ---- End: LAB Color Space
  makeupColor = lab2rgb(makeupLab);

  // Reflection layer
  float reflectionIntensity = shineAlpha * uMakeupReflectiveness;
  vec3 makeupWithReflection = makeupColor * 0.85 + reflectionIntensity * getReflectionColor();
  makeupColor = mix(makeupColor, makeupWithReflection, min(1.0, uMakeupReflectiveness));

  gl_FragColor = vec4(makeupColor, finalAlpha);
}
