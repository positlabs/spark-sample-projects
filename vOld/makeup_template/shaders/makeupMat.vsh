// Copyright 2004-present Facebook. All Rights Reserved.
//
// DO NOT MODIFY THIS FILE
//
// Any changes made to this file will make your effect be rejected from IG Creators

precision highp float;

attribute vec3 a_Position;
attribute vec3 a_Normal;
attribute vec2 a_TexCoords;

uniform mat4 u_MVPMatrix;
uniform mat4 u_NormalMatrix;

varying vec2 v_TexCoords;
varying vec3 v_ReflectionVec;

mat3 mat3_emu(mat4 m4) {
  return mat3(
      m4[0][0], m4[0][1], m4[0][2],
      m4[1][0], m4[1][1], m4[1][2],
      m4[2][0], m4[2][1], m4[2][2]);
}

vec4 projectedPosition() {
  return u_MVPMatrix * vec4(a_Position, 1.0);
}

void main() {
  gl_Position = projectedPosition();

  mat3 trackerMat = mat3(
    1.0, 0.0, 0.0,
    0.0, 1.0, 0.0,
    0.0, 0.0, 1.0
  );

  v_ReflectionVec = mat3_emu(u_NormalMatrix) * trackerMat * a_Normal;
  v_TexCoords = a_TexCoords;
}
