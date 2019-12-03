//Header
//Copyright 20__-present, Facebook, Inc.
//All rights reserved.

//This source code is licensed under the license found in the
//LICENSE file in the root directory of this source tree.
var Animation = require('Animation');
var FaceTracking = require('FaceTracking');
var Scene = require('Scene');

var ft = Scene.root.child("Device").child("Camera").child("Focal Distance").child("facetracker0");

var pizzaWheel0 = ft.child("pizzas_123");
var pizzaWheel1 = ft.child("pizzas_456");
var pizzaWheel2 = ft.child("pizzas_789");

var mouthIsOpen = FaceTracking.face(0).mouth.openness.gt(0.3).and(FaceTracking.count.gt(0));

pizzaWheel0.hidden = pizzaWheel1.hidden = pizzaWheel2.hidden = mouthIsOpen.not();

var wheelDriver = Animation.timeDriver({durationMilliseconds: 2500, loopCount: Infinity});
var wheelSampler = Animation.samplers.linear(0, -Math.PI*2);

pizzaWheel0.transform.rotationX = Animation.animate(wheelDriver, wheelSampler);
pizzaWheel1.transform.rotationX = Animation.animate(wheelDriver, wheelSampler);
pizzaWheel2.transform.rotationX = Animation.animate(wheelDriver, wheelSampler);

mouthIsOpen.monitor().subscribe( function(e) {
  if (e.newValue == true) {
    wheelDriver.start();
  } else {
  	wheelDriver.stop();
  	wheelDriver.reset();
  }
});
