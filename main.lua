--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

display.setStatusBar(display.HiddenStatusBar)
math.randomseed(os.time())

system.activate("mouse")

-- ***** --

local prism = require("prism")

local particlesText = display.newText({
	text = "_ particles",
	fontSize = 24
})

local clickText = display.newText({
	text = "Left-click to move emission point; right-click to move emitter",
	fontSize = 22
})
clickText.x, clickText.y = display.contentCenterX, display.contentHeight - display.screenOriginY - clickText.height * 0.5 - 10

local emitter = prism.newEmitter({
	-- Particle building and emission options
	particles = {
		type = "image",
		image = "particle.png",
		width = 100,
		height = 100,
		color = {{1, 1, 0.1}, {1, 0, 0}},
		blendMode = "add",
		particlesPerEmission = 10,
		delayBetweenEmissions = 100,
		inTime = 100,
		lifeTime = 100,
		outTime = 1000,
		startProperties = {xScale = 1, yScale = 1},
		endProperties = {xScale = 0.3, yScale = 0.3}
	},
	-- Particle positioning options
	position = {
		type = "point"
	},
	-- Particle movement options
	movement = {
		type = "angular",
		angle = "0-359",
		velocityRetain = .97,
		speed = 1,
		yGravity = -0.15
	}
})

emitter.emitX, emitter.emitY = display.contentCenterX, display.contentCenterY
emitter:startEmitTimer()

Runtime:addEventListener("enterFrame", function()
	particlesText.text = emitter.numChildren .. " particles"
	particlesText.x, particlesText.y = display.contentCenterX, display.screenOriginY + particlesText.height * 0.5
end)

Runtime:addEventListener("mouse", function(event)
	if event.isPrimaryButtonDown then
		emitter.emitX, emitter.emitY = emitter:contentToLocal(event.x, event.y)
	elseif event.isSecondaryButtonDown then
		emitter.x, emitter.y = event.x - emitter.emitX, event.y - emitter.emitY
	end
end)

-- timer.performWithDelay(1000, function() emitter:pauseEffect() end)
-- timer.performWithDelay(2000, function() emitter:resumeEffect() end)

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

-- Changing particle positions:
-- 1. Setting the vent's X and Y directly will move the entire vent and all particles relative to it. This may be what you want, but in most cases you'll need option 2.
-- 2. Setting the vent's emitX and emitY properties will move the point at which particles are emitted. This is *relative to the emitter*, so if the emitter's position is something other than 0, you'll need to localize the coordinates of the point you want.
