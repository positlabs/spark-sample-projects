// Copyright 2004-present Facebook. All Rights Reserved.
//
// DO NOT MODIFY THIS FILE
//
// Any changes made to this file will make your effect be rejected from IG Creators

precision highp float;

attribute vec3 position;

varying highp vec2 v_uv;

void main() {
  gl_Position = vec4(position, 1.0);
  v_uv = position.xy * 0.5 + 0.5;
}
