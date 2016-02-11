--------------------------------------------------------------------------------
--[[
Prism

Version 0.1.0
--]]
--------------------------------------------------------------------------------

local lib_prism = {}

lib_prism.config = {
	angleRangeCalculationGranularity = 1,
	transitionMovementStopSafeguardLevel = 100,
	emitOnEmissionStart = false,
	enableDeltaTimeCalculation = true,
	removeOffscreenParticles = false,
	automaticallyUpdateEmitters = true,
	randomMovementRange = 10,
	numberColorIncludesAlpha = false,
}

local emitters = {}

--------------------------------------------------------------------------------
-- Localize
--------------------------------------------------------------------------------
local pairs = pairs
local tonumber = tonumber
local type = type
local math_cos = math.cos
local math_rad = math.rad
local math_random = math.random
local math_sin = math.sin
local string_match = string.match
local table_insert = table.insert
local display_newCircle = display.newCircle
local display_newGroup = display.newGroup
local display_newImage = display.newImage
local display_newImageRect = display.newImageRect
local display_newRect = display.newRect
local display_remove = display.remove
local physics_addBody = (physics ~= nil and physics.addBody) or function() print("Error: Physics engine not loaded.") error() end
local system_getTimer = system.getTimer
local timer_cancel = timer.cancel
local timer_pause = timer.pause
local timer_performWithDelay = timer.performWithDelay
local timer_resume = timer.resume
local transition_cancel = transition.cancel
local transition_pause = transition.pause
local transition_resume = transition.resume
local transition_to = transition.to

local distanceBetween = function(x1, y1, x2, y2) local xDiff = x2 - x1 local yDiff = y2 - y1 local distanceBetween = ((xDiff * xDiff) + (yDiff * yDiff)) ^ 0.5 return distanceBetween, xDiff, yDiff end
local forcesByAngle = function(totalForce, angle) local forces = {} local radians = -math_rad(angle) forces.x = math_cos(radians) * totalForce forces.y = math_sin(radians) * totalForce return forces end

local deviceLeft, deviceRight = display.screenOriginX, display.contentWidth - display.screenOriginX
local deviceTop, deviceBottom = display.screenOriginY, display.contentHeight - display.screenOriginY

--------------------------------------------------------------------------------
-- Core EnterFrame Listeners
--------------------------------------------------------------------------------
local deltaTimeCalculationOn = false
local wasDeltaTimeCalculationOn = false
local globalDeltaTime = 1
local prevTime = 0
local fps = display.fps
local msPerFrame = 1000 / fps

local calculateDeltaTime = function(event)
	local timeDiff = event.time - prevTime
	globalDeltaTime = timeDiff / msPerFrame
	prevTime = event.time
end

local updateEmitters = function()
	if not lib_prism.config.automaticallyUpdateEmitters then return end
	for k, v in pairs(emitters) do
		v:updateParticles()
	end
end

local setUseDeltaTimeCalculation = function(d)
	if not lib_prism.config.enableDeltaTimeCalculation then return end
	if d and not deltaTimeCalculationOn then
		prevTime = system_getTimer()
		Runtime:addEventListener("enterFrame", calculateDeltaTime)
	elseif not d and globalDeltaTimeCalculationOn then
		Runtime:removeEventListener("enterFrame", calculateDeltaTime)
	end
	deltaTimeCalculationOn = d
end

local onSystemEvent = function(event)
	if event.type == "applicationSuspend" then
		wasDeltaTimeCalculationOn = deltaTimeCalculationOn
		setUseDeltaTimeCalculation(false)
	elseif event.type == "applicationResume" then
		setUseDeltaTimeCalculation(wasDeltaTimeCalculationOn)
	end
end

setUseDeltaTimeCalculation(true)
Runtime:addEventListener("system", onSystemEvent)
Runtime:addEventListener("enterFrame", updateEmitters)
lib_prism.setUseDeltaTimeCalculation = setUseDeltaTimeCalculation

--------------------------------------------------------------------------------
-- Prism Library Utility Functions
--------------------------------------------------------------------------------
lib_prism.setTargetFPS = function(v)
	fps = v
	msPerFrame = 1000 / fps
end

--------------------------------------------------------------------------------
-- New Emitter
--------------------------------------------------------------------------------
lib_prism.newEmitter = function(params)
	local emitter = display_newGroup()
	local params = params or {}
	local numTimelineParameters, isPaused, emitTimer = 0, false, nil

	local config_angleRangeCalculationGranularity = lib_prism.config.angleRangeCalculationGranularity
	local config_transitionMovementStopSafeguardLevel = lib_prism.config.transitionMovementStopSafeguardLevel
	local config_emitOnEmissionStart = lib_prism.config.emitOnEmissionStart
	local config_removeOffscreenParticles = lib_prism.config.removeOffscreenParticles
	local config_randomMovementRange = lib_prism.config.randomMovementRange

	local positionParticle, addParticleMovement
	local particles = {}
	
	emitter.emitX, emitter.emitY = 0, 0

	------------------------------------------------------------------------------
	-- Set Options
	------------------------------------------------------------------------------
	local options = {}

	local particleType = params.particles or {}
		particleType.type = particleType.type or "circle"
		particleType.width = particleType.width or 10
		particleType.height = particleType.height or 10
		particleType.color = particleType.color or {1, 1, 1}
		particleType.image = particleType.image or "particle.png"
		particleType.blendMode = particleType.blendMode or "normal"
		particleType.getParticle = particleType.getParticle
		particleType.delayBetweenEmissions = particleType.delayBetweenEmissions or 100
		particleType.emissionCount = particleType.emissionCount or 0
		particleType.particlesPerEmission = particleType.particlesPerEmission or 1
		particleType.physicsParameters = particleType.physicsParameters
		particleType.inTime = particleType.inTime or 100
		particleType.lifeTime = particleType.lifeTime or 100
		particleType.outTime = particleType.outTime or 100
		particleType.startAlpha = particleType.startAlpha or 0
		particleType.lifeAlpha = particleType.lifeAlpha or 1
		particleType.endAlpha = particleType.endAlpha or 0
		particleType.startProperties = particleType.startProperties or {}
		particleType.lifeProperties = particleType.lifeProperties or {}
		particleType.endProperties = particleType.endProperties or {}

	local positionType = params.position or {}
		positionType.type = positionType.type or "ellipse"
		positionType.width = positionType.width or 100
		positionType.height = positionType.height or 100
		positionType.offsetX = positionType.offsetX or 0
		positionType.offsetY = positionType.offsetY or 0

	local movementType = params.movement or {}
		movementType.type = movementType.type or "awayFromOffsetPosition"
		movementType.angle = movementType.angle or 0
		movementType.speed = movementType.speed or 0.5
		movementType.targetOffsetX = movementType.targetOffsetX or 0
		movementType.targetOffsetY = movementType.targetOffsetY or 0
		movementType.angleSequentialIncrement = movementType.angleSequentialIncrement or 1
		movementType.getVelocity = movementType.getVelocity
		movementType.velocityRetain = movementType.velocityRetain or 1
		movementType.xVelocityRetain = movementType.xVelocityRetain
		movementType.yVelocityRetain = movementType.yVelocityRetain
		movementType.xGravity = movementType.xGravity or 0
		movementType.yGravity = movementType.yGravity or 0
		movementType.method = movementType.method

	options.particles = particleType
	options.position = positionType
	options.movement = movementType

	emitter.options = options

	------------------------------------------------------------------------------
	-- Localize Particle Values
	------------------------------------------------------------------------------
	local
		ptt_type, ptt_width, ptt_height, ptt_halfWidth, ptt_getParticle, ptt_color, ptt_processedColor, ptt_numColors, ptt_image, ptt_blendMode, ptt_timeline, ptt_delayBetweenEmissions, ptt_emissionCount, ptt_particlesPerEmission, ptt_physicsParameters, ptt_inTime, ptt_lifeTime, ptt_outTime, ptt_lifeSpan, ptt_startAlpha, ptt_lifeAlpha, ptt_endAlpha, ptt_startProperties, ptt_lifeProperties, ptt_endProperties,
		pst_type, pst_width, pst_height, pst_halfWidth, pst_halfHeight, pst_offsetX, pst_offsetY,
		mvt_type, mvt_speed, mvt_targetOffsetX, mvt_targetOffsetY, mvt_angle, mvt_derivedAngles, mvt_calculatedAngles, mvt_numCalculatedAngles, mvt_currentAngle, mvt_angleSequentialIncrement, mvt_getVelocity, mvt_speed, mvt_xVelocityRetain, mvt_yVelocityRetain, mvt_xGravity, mvt_yGravity

	function emitter:refreshOptions()
		ptt_type = particleType.type
		ptt_width = particleType.width
		ptt_height = particleType.height
		ptt_halfWidth = particleType.width * 0.5
		ptt_getParticle = particleType.getParticle
		ptt_image = particleType.image
		ptt_color = particleType.color
		ptt_lifeSpan = particleType.lifeSpan
		ptt_blendMode = particleType.blendMode
		ptt_timeline = particleType.timeline
		ptt_delayBetweenEmissions = particleType.delayBetweenEmissions
		ptt_emissionCount = particleType.emissionCount
		ptt_particlesPerEmission = particleType.particlesPerEmission
		ptt_physicsParameters = particleType.physicsParameters
		
		ptt_inTime = particleType.inTime
		ptt_lifeTime = particleType.lifeTime
		ptt_outTime = particleType.outTime
		ptt_lifeSpan = ptt_inTime + ptt_lifeTime + ptt_outTime
		ptt_startAlpha = particleType.startAlpha
		ptt_lifeAlpha = particleType.lifeAlpha
		ptt_endAlpha = particleType.endAlpha
		ptt_startProperties = particleType.startProperties
		ptt_lifeProperties = particleType.lifeProperties
		ptt_endProperties = particleType.endProperties

		pst_type = positionType.type
		pst_width = positionType.width
		pst_height = positionType.height
		pst_halfWidth = pst_width * 0.5
		pst_halfHeight = pst_height * 0.5
		pst_offsetX = positionType.offsetX
		pst_offsetY = positionType.offsetY

		mvt_type = movementType.type
		mvt_angle = movementType.angle
		mvt_angleSequentialIncrement = movementType.angleSequentialIncrement
		mvt_getVelocity = movementType.getVelocity
		mvt_speed = movementType.speed
		mvt_xVelocityRetain = movementType.xVelocityRetain or movementType.velocityRetain
		mvt_yVelocityRetain = movementType.yVelocityRetain or movementType.velocityRetain
		mvt_xGravity = movementType.xGravity
		mvt_yGravity = movementType.yGravity
		mvt_targetOffsetX = movementType.targetOffsetX
		mvt_targetOffsetY = movementType.targetOffsetY

		mvt_derivedAngles = {}
		mvt_calculatedAngles = {}
		mvt_numCalculatedAngles = 0
		mvt_currentAngle = 1
		
		ptt_processedColor = {}
		ptt_numColors = 0
		
		emitter:processAngles()
		emitter:processColor()
	end

	------------------------------------------------------------------------------
	-- Position Particle
	------------------------------------------------------------------------------
	positionParticle = function(particle)
		if pst_type == "point" then
			particle.x, particle.y = pst_offsetX + emitter.emitX, pst_offsetY + emitter.emitY
		elseif pst_type == "ellipse" and pst_width > 0 and pst_height > 0 then
			local pointX, pointY
			while true do
				pointX, pointY = math_random(-pst_halfWidth, pst_halfWidth), math_random(-pst_halfHeight, pst_halfHeight)
				local inOuter
				do
					local xSquared = pointX * pointX
					local ySquared = pointY * pointY
					local xRadiusSquared = pst_halfWidth * pst_halfWidth
					local yRadiusSquared = pst_halfHeight * pst_halfHeight
					inOuter = (xSquared / xRadiusSquared) + (ySquared / yRadiusSquared) <= 1
				end
				if inOuter and not (pointX == pst_offsetX and pointY == pst_offsetY) then break end
			end
			particle.x, particle.y = pointX + pst_offsetX + emitter.emitX, pointY + pst_offsetY + emitter.emitY
		elseif pst_type == "rectangle" then
			local pointX, pointY = math_random(-pst_halfWidth, pst_halfWidth), math_random(-pst_halfHeight, pst_halfHeight)
			particle.x, particle.y = pointX + pst_offsetX + emitter.emitX, pointY + pst_offsetY + emitter.emitY
		end
	end -- positionParticle()

	------------------------------------------------------------------------------
	-- Add Movement to Particle
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	-- Frame-Based Movement
	------------------------------------------------------------------------------
	if not movementType.method or movementType.method == "frameBased" then
		addParticleMovement = function(particle)
			local xVelocity, yVelocity

			if mvt_type == "none" then
				xVelocity, yVelocity = 0, 0
			--------------------------------------------------------------------------
			-- Random
			--------------------------------------------------------------------------
			elseif mvt_type == "random" then
				repeat xVelocity, yVelocity = math_random(-config_randomMovementRange, config_randomMovementRange), math_random(-config_randomMovementRange, config_randomMovementRange) until (xVelocity ~= 0 or yVelocity ~= 0)
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Angular
			--------------------------------------------------------------------------
			elseif mvt_type == "angular" then
				if mvt_numCalculatedAngles == 1 then
					xVelocity, yVelocity = mvt_calculatedAngles[1].x, mvt_calculatedAngles[1].y
				else
					local angle = mvt_calculatedAngles[math_random(mvt_numCalculatedAngles)]
					xVelocity, yVelocity = angle.x, angle.y
				end
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Sequentially Angular
			--------------------------------------------------------------------------
			elseif mvt_type == "angularSequential" then
				local angle = mvt_calculatedAngles[mvt_currentAngle]
				xVelocity, yVelocity = angle.x * mvt_speed, angle.y * mvt_speed
				mvt_currentAngle = (((mvt_currentAngle + mvt_angleSequentialIncrement) - 1) % (mvt_numCalculatedAngles)) + 1
			--------------------------------------------------------------------------
			-- Away from Offset Position
			--------------------------------------------------------------------------
			elseif mvt_type == "awayFromOffsetPosition" then
				xVelocity, yVelocity = particle.x - mvt_targetOffsetX, particle.y - mvt_targetOffsetY
				if positionType.type == "point" and (mvt_targetOffsetX == 0 and mvt_targetOffsetY == 0) then repeat xVelocity, yVelocity = math_random(-10, 10), math_random(-10, 10) until (xVelocity ~= 0 or yVelocity ~= 0) end
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Toward Offset Position
			--------------------------------------------------------------------------
			elseif mvt_type == "towardsOffsetPosition" then
				xVelocity, yVelocity = mvt_targetOffsetX - particle.x, mvt_targetOffsetY - particle.y
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Custom
			--------------------------------------------------------------------------
			elseif mvt_type == "customFunction" then
				xVelocity, yVelocity = mvt_getVelocity({
					particle = particle,
					emitter = emitter
				})
				if not (xVelocity and yVelocity) then print("Warning: getVelocity() returned invalid value.") xVelocity, yVelocity = 0, 0 end
			else
				print("Warning: Unsupported movement type '" .. mvt_type .. "'")
			end

			if xVelocity and yVelocity then
				particle._prism_xVelocity, particle._prism_yVelocity = xVelocity, yVelocity
			else
				particle._prism_xVelocity, particle._prism_yVelocity = 0, 0
			end
		end

	------------------------------------------------------------------------------
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	-- Box2D Physics Particle Movement
	------------------------------------------------------------------------------
	elseif movementType.method == "physics" then
		addParticleMovement = function(particle)
			local xVelocity, yVelocity

			if mvt_type == "none" then
				xVelocity, yVelocity = 0, 0
			--------------------------------------------------------------------------
			-- Random
			--------------------------------------------------------------------------
			elseif mvt_type == "random" then
				repeat xVelocity, yVelocity = math_random(-config_randomMovementRange, config_randomMovementRange), math_random(-config_randomMovementRange, config_randomMovementRange) until (xVelocity ~= 0 or yVelocity ~= 0)
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Angular
			--------------------------------------------------------------------------
			elseif mvt_type == "angular" then
				if mvt_numCalculatedAngles == 1 then
					xVelocity, yVelocity = mvt_calculatedAngles[1].x, mvt_calculatedAngles[1].y
				else
					local angle = mvt_calculatedAngles[math_random(mvt_numCalculatedAngles)]
					xVelocity, yVelocity = angle.x, angle.y
				end
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Sequentially Angular
			--------------------------------------------------------------------------
			elseif mvt_type == "angularSequential" then
				local angle = mvt_calculatedAngles[mvt_currentAngle]
				xVelocity, yVelocity = angle.x * mvt_speed, angle.y * mvt_speed
				mvt_currentAngle = (((mvt_currentAngle + mvt_angleSequentialIncrement) - 1) % (mvt_numCalculatedAngles)) + 1
			--------------------------------------------------------------------------
			-- Away from Target
			--------------------------------------------------------------------------
			elseif mvt_type == "awayFromOffsetPosition" then
				xVelocity, yVelocity = particle.x - mvt_targetOffsetX, particle.y - mvt_targetOffsetY
				if positionType.type == "point" and (mvt_targetOffsetX == 0 and mvt_targetOffsetY == 0) then repeat xVelocity, yVelocity = math_random(-10, 10), math_random(-10, 10) until (xVelocity ~= 0 or yVelocity ~= 0) end
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Toward Target
			--------------------------------------------------------------------------
			elseif mvt_type == "towardsOffsetPosition" then
				xVelocity, yVelocity = mvt_targetOffsetX - particle.x, mvt_targetOffsetY - particle.y
				xVelocity, yVelocity = xVelocity * mvt_speed, yVelocity * mvt_speed
			--------------------------------------------------------------------------
			-- Custom
			--------------------------------------------------------------------------
			elseif mvt_type == "customFunction" then
				xVelocity, yVelocity = mvt_getVelocity({
					particle = particle,
					emitter = emitter
				})
				if not (xVelocity and yVelocity) then print("Warning: getVelocity() returned invalid value.") xVelocity, yVelocity = 0, 0 end
			else
				print("Warning: Unsupported movement type '" .. mvt_type .. "'")
			end

			physics_addBody(particle, ptt_physicsParameters)
			if xVelocity and yVelocity then
				particle:setLinearVelocity(xVelocity, yVelocity)
			end
		end

	------------------------------------------------------------------------------
	------------------------------------------------------------------------------

	------------------------------------------------------------------------------
	-- Transition-Based Particle Movement
	------------------------------------------------------------------------------
	elseif movementType.method == "transition" then
		addParticleMovement = function(particle)
			local outX, outY, isExtrudeTransitionBased

			if mvt_type == "none" then
				-- Do nothing
			--------------------------------------------------------------------------
			-- Random
			--------------------------------------------------------------------------
			elseif mvt_type == "random" then
				repeat outX, outY = math_random(-config_randomMovementRange, config_randomMovementRange), math_random(-config_randomMovementRange, config_randomMovementRange) until (outX ~= 0 or outY ~= 0)
				isExtrudeTransitionBased = true
			--------------------------------------------------------------------------
			-- Angular
			--------------------------------------------------------------------------
			elseif mvt_type == "angular" then
				if mvt_numCalculatedAngles == 1 then
					outX, outY = mvt_calculatedAngles[1].x, mvt_calculatedAngles[1].y
				else
					local angle = mvt_calculatedAngles[math_random(mvt_numCalculatedAngles)]
					outX, outY = angle.x, angle.y
				end
				isExtrudeTransitionBased = true
			--------------------------------------------------------------------------
			-- Sequentially Angular
			--------------------------------------------------------------------------
			elseif mvt_type == "angularSequential" then
				local angle = mvt_calculatedAngles[mvt_currentAngle]
				outX, outY = angle.x, angle.y

				mvt_currentAngle = (((mvt_currentAngle + mvt_angleSequentialIncrement) - 1) % (mvt_numCalculatedAngles)) + 1
				isExtrudeTransitionBased = true
			--------------------------------------------------------------------------
			-- Away from Target
			--------------------------------------------------------------------------
			elseif mvt_type == "awayFromOffsetPosition" then
				outX, outY = particle.x - mvt_targetOffsetX, particle.y - mvt_targetOffsetY
				if positionType.type == "point" and (mvt_targetOffsetX == 0 and mvt_targetOffsetY == 0) then repeat outX, outY = math_random(-10, 10), math_random(-10, 10) until (outX ~= 0 or outY ~= 0) end
				isExtrudeTransitionBased = true
			--------------------------------------------------------------------------
			-- Toward Offset Position
			--------------------------------------------------------------------------
			elseif mvt_type == "towardsOffsetPosition" then
				outX, outY = mvt_targetOffsetX - particle.x, mvt_targetOffsetY - particle.y
				isExtrudeTransitionBased = true
			--------------------------------------------------------------------------
			-- Toward Offset Position (clamped)
			--------------------------------------------------------------------------
			elseif mvt_type == "towardsOffsetPositionClamped" then
				particle._prism_movementTransition = transition_to(particle, {time = particleType.lifeSpan, x = mvt_targetOffsetX, y = mvt_targetOffsetY})
			else
				print("Warning: Unsupported movement type '" .. mvt_type .. "'")
			end
			--------------------------------------------------------------------------
			-- Extrude Transition-based Movement (random, awayFromOffsetPosition, towardOffsetPosition, etc.)
			--------------------------------------------------------------------------
			if isExtrudeTransitionBased then
				local dist, xDiff, yDiff = distanceBetween(particle.x, particle.y, outX + particle.x, outY + particle.y)
				if dist == 0 then dist = 1 end

				local normX, normY = xDiff / dist, yDiff / dist

				local maxDist = ptt_lifeSpan * mvt_speed + config_transitionMovementStopSafeguardLevel
				local extrudedX, extrudedY = normX * maxDist, normY * maxDist

				local transitionTime = maxDist / mvt_speed
				particle._prism_movementTransition = transition_to(particle, {time = transitionTime, delta = true, x = extrudedX, y = extrudedY})
			end
		end -- addParticleMovement()
	end -- movementType.method

	------------------------------------------------------------------------------
	-- Move Particles
	------------------------------------------------------------------------------
	if not movementType.method or movementType.method == "frameBased" then
		function emitter:updateParticles()
			if isPaused then return end

			for i = emitter.numChildren, 1, -1 do
				local p = emitter[i]
				-- if p._prism_isParticle then
					local xVelocity, yVelocity = p._prism_xVelocity, p._prism_yVelocity
					xVelocity = xVelocity * mvt_xVelocityRetain + mvt_xGravity * globalDeltaTime
					yVelocity = yVelocity * mvt_yVelocityRetain + mvt_yGravity * globalDeltaTime

					p:translate(xVelocity * globalDeltaTime, yVelocity * globalDeltaTime)
					
					p._prism_xVelocity, p._prism_yVelocity = xVelocity, yVelocity
					
					if config_removeOffscreenParticles then
						local contentX, contentY = p:localToContent(0, 0)
						local hw, hh = p.contentWidth * 0.5, p.contentHeight * 0.5
						if contentX + hw < deviceLeft or contentX - hw > deviceRight or contentY + hh < deviceTop or contentY - hh > deviceBottom then
							display_remove(p)
							p = nil
						end
					end
				-- end -- if p._prism_isParticle - uncomment if you insert things into the emitter
			end
		end
	else
		function emitter:updateParticles()
			if isPaused then return end
			if config_removeOffscreenParticles then
				for i = emitter.numChildren, 1, -1 do
					local p = emitter[i]
					
					-- if p._prism_isParticle then
						local contentX, contentY = p:localToContent(0, 0)
						local hw, hh = p.contentWidth * 0.5, p.contentHeight * 0.5
						if contentX + hw < deviceLeft or contentX - hw > deviceRight or contentY + hh < deviceTop or contentY - hh > deviceBottom then
							display_remove(p)
							p = nil
						end
					-- end
				end
			end
		end
	end

	------------------------------------------------------------------------------
	-- Process Angles
	------------------------------------------------------------------------------
	function emitter:processAngles()
		if mvt_type ~= "angular" and mvt_type ~= "angularSequential" then return end -- Don't recalculate if we don't need to
		mvt_derivedAngles = {}
		mvt_calculatedAngles = {}

		local angleType = type(mvt_angle)

		if angleType == "number" then
			table_insert(mvt_derivedAngles, mvt_angle)
		elseif angleType == "table" then
			for i = 1, #mvt_angle do
				local thisAngle = mvt_angle[i]
				local thisAngleType = type(thisAngle)
				if thisAngleType == "string" then
					local firstAngle, secondAngle = string_match(thisAngle, "([^%-]+)%-([^%-]+)")
					for i = firstAngle, secondAngle, config_angleRangeCalculationGranularity do table_insert(mvt_derivedAngles, i) end
				elseif thisAngleType == "number" then
					table_insert(mvt_derivedAngles, thisAngle)
				end
			end
		elseif angleType == "string" then
			local firstAngle, secondAngle = string_match(mvt_angle, "([^%-]+)%-([^%-]+)")
			for i = firstAngle, secondAngle, config_angleRangeCalculationGranularity do table_insert(mvt_derivedAngles, i) end
		end

		for i = 1, #mvt_derivedAngles do
			table_insert(mvt_calculatedAngles, forcesByAngle(1, mvt_derivedAngles[i]))
		end

		mvt_numCalculatedAngles = #mvt_calculatedAngles
	end -- emitter:processAngles()

	------------------------------------------------------------------------------
	-- Process Color
	------------------------------------------------------------------------------
	function emitter:processColor()
		local i = 1
		while ptt_color[i] ~= nil do
			local color = ptt_color[i]
			local colorType = type(color)
			local processed = {}
			
			if colorType == "number" then
				local r, g, b = color, ptt_color[i + 1], ptt_color[i + 2]
				i = i + 3
				local a
				if lib_prism.config.numberColorIncludesAlpha then
					if type(ptt_color[i]) == "number" then
						a = ptt_color[i]
						i = i + 1
					end
				end
				processed = {r, g, b, a}
			elseif colorType == "table" then
				processed = color
				i = i + 1
			end
			
			ptt_processedColor[#ptt_processedColor + 1] = processed
		end
		ptt_numColors = #ptt_processedColor
	end

	------------------------------------------------------------------------------
	-- Create Particle
	------------------------------------------------------------------------------
	function emitter:buildParticle()
		local particle
		local addFinished, updateForTime

		local lifeTimer

		----------------------------------------------------------------------------
		-- Create Particle
		----------------------------------------------------------------------------
		if ptt_type == "circle" then
			particle = display_newCircle(0, 0, ptt_halfWidth)
		elseif ptt_type == "rectangle" then
			particle = display_newRect(0, 0, ptt_width, ptt_height)
		elseif ptt_type == "image" then
			particle = display_newImageRect(ptt_image, ptt_width, ptt_height)
		elseif ptt_type == "custom" then
			particle = ptt_getParticle({
				emitter = emitter
			})
		end

		particle.blendMode = ptt_blendMode
		particle._prism_isParticle = true

		if ptt_numColors == 1 then
			local c = ptt_processedColor[1]
			particle:setFillColor(c[1], c[2], c[3], c[4] or 1)
		else
			local c = ptt_processedColor[math_random(ptt_numColors)]
			particle:setFillColor(c[1], c[2], c[3], c[4] or 1)
		end

		for k, v in pairs(ptt_startProperties) do particle[k] = v end

		----------------------------------------------------------------------------
		-- Particle Finalize Listener
		----------------------------------------------------------------------------
		function particle:finalize()
			if emitter and emitter.x then
				emitter:dispatchEvent({
					name = "particle",
					phase = "lifeEnded",
					target = particle
				})
			end

			transition_cancel(self)
			particle = nil
		end
		
		----------------------------------------------------------------------------
		-- Begin Life Span
		----------------------------------------------------------------------------
		function particle:_prism_beginParticleLife()
			emitter:dispatchEvent({
				name = "particle",
				phase = "lifeBegan",
				target = particle
			})
			particle.alpha = ptt_startAlpha
			local options = {}
						
			for k, v in pairs(ptt_lifeProperties) do
				options[k] = v
			end
			
			options.alpha = ptt_lifeAlpha
			options.time = ptt_inTime
			
			options.onComplete = function()
				local options = {}
				for k, v in pairs(ptt_lifeProperties) do particle[k] = v end
				for k, v in pairs(ptt_endProperties) do options[k] = v end
				options.alpha = ptt_endAlpha
				options.time = ptt_outTime
				options.delay = ptt_lifeTime
				options.onComplete = function()
					display_remove(particle)
					particle = nil
				end
				particle._prism_lifeTransition = transition_to(particle, options)
			end
			
			particle._prism_lifeTransition = transition_to(particle, options)
		end

		particle:addEventListener("finalize")
		emitter:insert(particle)
		return particle
	end -- emitter:buildParticle()

	------------------------------------------------------------------------------
	-- Emit Particles
	------------------------------------------------------------------------------
	function emitter:emit()
		for i = 1, ptt_particlesPerEmission do
			local particle = emitter:buildParticle()
			positionParticle(particle)
			addParticleMovement(particle)
			particle:_prism_beginParticleLife()
		end
	end

	------------------------------------------------------------------------------
	-- Start Emit Timer
	------------------------------------------------------------------------------
	function emitter:startEmitTimer()
		if emitTimer then timer_cancel(emitTimer) end
		if config_emitOnEmissionStart then emitter:emit() end
		emitTimer = timer_performWithDelay(ptt_delayBetweenEmissions, function(event)
			emitter:emit()
			-- if event.count == ptt_emissionCount then
				-- emitTimer = nil
			-- end
		end, ptt_emissionCount)
	end

	------------------------------------------------------------------------------
	-- Stop Emit Timer
	------------------------------------------------------------------------------
	function emitter:stopEmitTimer()
		if emitTimer then timer_cancel(emitTimer) end
	end

	------------------------------------------------------------------------------
	-- Particle Iterator
	------------------------------------------------------------------------------
	function emitter:eachParticle()
		local i = self.numChildren + 1
		return function()
			i = i - 1
			local particle = self[i]
			while particle and not particle._prism_isParticle do i = i - 1 particle = self[i] end
			return particle
		end
	end

	------------------------------------------------------------------------------
	-- Pause
	------------------------------------------------------------------------------
	function emitter:pauseEffect()
		isPaused = true
		if emitTimer then timer_pause(emitTimer) end
		for i = self.numChildren, 1, -1 do
			if self[i]._prism_isParticle then transition_pause(self[i]) end
			self[i].isBodyActive = false
		end
		self.isPaused = true
	end

	------------------------------------------------------------------------------
	-- Resume
	------------------------------------------------------------------------------
	function emitter:resumeEffect()
		isPaused = false
		if emitTimer then timer_resume(emitTimer) end
		for i = self.numChildren, 1, -1 do
			if self[i]._prism_isParticle then transition_resume(self[i]) end
			self[i].isBodyActive = true
		end
		self.isPaused = false
	end
	
	------------------------------------------------------------------------------
	-- Finalize Listener
	------------------------------------------------------------------------------
	function emitter:finalize(event)
		emitters[self] = nil
		if emitTimer then timer_cancel(emitTimer) end
		for i = self.numChildren, 1, -1 do
			if self[i]._prism_isParticle then
				display_remove(self[i])
				self[i] = nil
			end
		end
	end

	------------------------------------------------------------------------------
	-- Finish Up
	------------------------------------------------------------------------------
	emitter:refreshOptions()
	emitter:addEventListener("finalize")
	emitters[emitter] = emitter

	return emitter
end

return lib_prism