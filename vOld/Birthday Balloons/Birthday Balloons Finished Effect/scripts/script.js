//Header
//Copyright 20__-present, Facebook, Inc.
//All rights reserved.

//This source code is licensed under the license found in the
//LICENSE file in the root directory of this source tree.


var R = require("Reactive");
var A = require("Animation");
var S = require("Scene");
var T = require("TouchGestures");
var Audio = require("Audio");
var D = require('Diagnostics');

var frame_balloon_indices = [32, 26, 25, 23, 24, 34, 27];

var balloons = [];
var number_of_balloons = 39;
var number_of_low_explosive_balloons = 36;
var balloon_bounce_amount = 16;
var balloon_bounce_time = 8000;
var balloon_rotate_time = 30000;
var light_rotate_time = 300000;

var burst_length = 300;
var signle_emitter_burst_birth_rate = 10000;
var multi_emitter_burst_birth_rate = 2500;

var tapRegistrar = function(balloon) {
	T.onTap(balloon.rotater).subscribe(function(event) {
		balloon.audiosource.play()
		balloon.rotater.hidden = true;

		for (var i = 0; i < balloon.emitter.length; i++) {
			birthrate_driver = A.timeDriver({durationMilliseconds: burst_length});
			birthrate_sampler = A.samplers.easeOutQuart(balloon.emitter_target_birthrate[i], 0);
			balloon.emitter[i].birthrate = A.animate(birthrate_driver, birthrate_sampler);
			birthrate_driver.start();
		}
	});
}

/*
build balloons array:
balloons[]
	mover - scene object for y movement
	rotater - scene object for y rotation
	bounce_driver - animation driver for y movement
	rotate_driver - animation driver for y rotation
	bounce_sampler - animation sampler for y movement
	rotate_rando - animation sampler for y rotation
	emitter[] - array of emitters per balloon 1 emitter per colored balloon (0-35) 5 emitters for the polka dot balloons (36-38)
	emitter_target_birthrate[] = array of target birth rates for each emitter
*/

for (var i=0; i<number_of_balloons; i++){
	//get randomizers for movement and rotation
	var bounce_rando = getRandomArbitrary(0, balloon_bounce_amount)
	var up_down = Math.floor(getRandomArbitrary(0, 2))
	var spin_randomizer = Math.floor(getRandomArbitrary(0, 2))

	//build balloons array
	balloons[i] = {
		mover:
			frame_balloon_indices.indexOf(i) > -1 ?
				S.root.child("Device").child("Camera").child("Focal Distance").child("balloon_move_"+i) :
				S.root.child("balloon_group").child("balloon_move_"+i),
		rotater:
			frame_balloon_indices.indexOf(i) > -1 ?
				S.root.child("Device").child("Camera").child("Focal Distance").child("balloon_move_"+i).child("balloon_rot_"+i) :
				S.root.child("balloon_group").child("balloon_move_"+i).child("balloon_rot_"+i),
		bounce_driver: A.timeDriver({durationMilliseconds: balloon_bounce_time, loopCount: Infinity, mirror: true}),
		rotate_driver: A.timeDriver({durationMilliseconds: balloon_rotate_time, loopCount: Infinity}),
		bounce_sampler: null,
		rotate_sampler: null,
		audiosource: S.root.child("audiosource"+(i%5)),
		emitter:[],
		emitter_target_birthrate:[]
	}
	if (i<number_of_low_explosive_balloons){
		balloons[i].emitter[0] = balloons[i].mover.child("emitter_"+i+"_0");
		balloons[i].emitter_target_birthrate[0] = signle_emitter_burst_birth_rate;
	}
	else{
		for (var j=0; j<5; j++){
			balloons[i].emitter[j] = balloons[i].mover.child("emitter_"+i+"_"+j);
			balloons[i].emitter_target_birthrate[j] = multi_emitter_burst_birth_rate;
		}
	}

	//set balloon animation parameters
	var balloon_y = balloons[i].mover.transform.y.lastValue;
	if (up_down == 1){
		balloons[i].bounce_sampler = A.samplers.easeInOutSine(balloon_y, balloon_y + bounce_rando);
	}
	else{
		balloons[i].bounce_sampler = A.samplers.easeInOutSine(balloon_y, balloon_y - bounce_rando);
	}
	balloons[i].mover.transform.y = A.animate(balloons[i].bounce_driver, balloons[i].bounce_sampler);
	balloons[i].bounce_driver.start();

	if (spin_randomizer == 1){
		balloons[i].rotate_sampler = A.samplers.linear(0, Math.PI*2);
	}
	else{
		balloons[i].rotate_sampler = A.samplers.linear(0, -Math.PI*2);
	}
	balloons[i].rotater.transform.rotationY = A.animate(balloons[i].rotate_driver, balloons[i].rotate_sampler);
	balloons[i].rotate_driver.start();

	tapRegistrar(balloons[i]);
}


//light dome rotation
var light_ray = {
	rotate_driver: A.timeDriver({durationMilliseconds: light_rotate_time, loopCount: Infinity}),
	rotate_sampler: A.samplers.linear(0, Math.PI*2)
};

S.root.child("light_dome").transform.rotationY = A.animate(light_ray.rotate_driver, light_ray.rotate_sampler);
light_ray.rotate_driver.start();

//helper function
function getRandomArbitrary(min, max) {
  return Math.random() * (max - min) + min;
}


