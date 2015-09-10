--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())

-- ***** --

local prism = require("prism")

local emitter = prism.newEmitter({
	-- Particle building and emission options
	particles = {
		type = "image",
		width = 128,
		height = 128,
		blendMode = "add",
		particlesPerEmission = 5,
		inTime = 100,
		lifeTime = 100,
		outTime = 500
	},
	-- Particle positioning options
	position = {
		type = "point"
	},
	-- Particle movement options
	movement = {
		type = "random",
		velocityRetain = 0.98,
		xGravity = 0.3,
		yGravity = 0.3,
	}
})

emitter.x, emitter.y = display.contentCenterX, display.contentCenterY
emitter:startEmitTimer()

timer.performWithDelay(1000, function() emitter:pauseEffect() end)
timer.performWithDelay(2000, function() emitter:resumeEffect() end)

-- Other stuff:
---------------
-- emitter.options - the emitter's parameters; set them via emitter.options.[particles/position/movement].[parameterName] = x
--   Currently, you can only set options one at a time - things like emitter.options.particles = {...} aren't currently available
--   After setting emitter options, call emitter:refreshOptions() for your changes to take effect
-- emitter:emit() - emit one "round" of particles
-- emitter:startEmitTimer() - start the vent emitting with a timer
-- emitter:stopEmitTimer() - stop the vent's emit timer
-- emitter:pauseEffect() - pause the emitter
-- emitter:resumeEffect() - resume the emitter
-- emitter:eachParticle() - iterator for each particle in the emitter
--   e.g for particle in emitter:eachParticle() do
-- Emitters are display groups, so to layer them relative to your other objects, just insert them as you would anything else
-- Emitters dispatch events for event listeners; currently, you can listen for the event "particle", which will notify you when a particle is created or destroyed. More listeners are probably coming.
-- See 'parameters.txt' for each parameter available in the emitter options
