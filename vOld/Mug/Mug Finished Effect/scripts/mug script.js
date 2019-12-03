const Scene = require('Scene');
const TouchGestures = require('TouchGestures');

var planeTracker = Scene.root.find('planeTracker0');

TouchGestures.onTap().subscribe(function(gesture) {
	planeTracker.trackPoint(gesture.location);
});
