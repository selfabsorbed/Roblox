local CharacterFunctions = {}

function CharacterFunctions.Animate(character, player)
	local PetHumanoid = character:WaitForChild("Humanoid")
	local Script = character:WaitForChild("Animate")
	local pose = "Standing"

	local userNoUpdateOnLoopSuccess, userNoUpdateOnLoopValue = pcall(function() return UserSettings():IsUserFeatureEnabled("UserNoUpdateOnLoop") end)
	local userNoUpdateOnLoop = userNoUpdateOnLoopSuccess and userNoUpdateOnLoopValue

	local userAnimateScaleRunSuccess, userAnimateScaleRunValue = pcall(function() return UserSettings():IsUserFeatureEnabled("UserAnimateScaleRun") end)
	local userAnimateScaleRun = userAnimateScaleRunSuccess and userAnimateScaleRunValue

	local function getRigScale()
		if userAnimateScaleRun then
			return character:GetScale()
		else
			return 1
		end
	end

	local AnimationSpeedDampeningObject = Script:FindFirstChild("ScaleDampeningPercent")
	local HumanoidHipHeight = 2

	local EMOTE_TRANSITION_TIME = 0.1

	local currentAnim = ""
	local currentAnimInstance = nil
	local currentAnimTrack = nil
	local currentAnimKeyframeHandler = nil
	local currentAnimSpeed = 1.0

	local runAnimTrack = nil
	local runAnimKeyframeHandler = nil

	local PreloadedAnims = {}

	local animTable = {}
	local animNames = { 
		idle = 	{	
			{ id = "http://www.roblox.com/asset/?id=507766666", weight = 1 },
			{ id = "http://www.roblox.com/asset/?id=507766951", weight = 1 },
			{ id = "http://www.roblox.com/asset/?id=507766388", weight = 9 }
		},
		walk = 	{ 	
			{ id = "http://www.roblox.com/asset/?id=507777826", weight = 10 } 
		}, 
		run = 	{
			{ id = "http://www.roblox.com/asset/?id=507767714", weight = 10 } 
		}, 
		swim = 	{
			{ id = "http://www.roblox.com/asset/?id=507784897", weight = 10 } 
		}, 
		swimidle = 	{
			{ id = "http://www.roblox.com/asset/?id=507785072", weight = 10 } 
		}, 
		jump = 	{
			{ id = "http://www.roblox.com/asset/?id=507765000", weight = 10 } 
		}, 
		fall = 	{
			{ id = "http://www.roblox.com/asset/?id=507767968", weight = 10 } 
		}, 
		climb = {
			{ id = "http://www.roblox.com/asset/?id=507765644", weight = 10 } 
		}, 
		sit = 	{
			{ id = "http://www.roblox.com/asset/?id=2506281703", weight = 10 } 
		},	
		toolnone = {
			{ id = "http://www.roblox.com/asset/?id=507768375", weight = 10 } 
		},
		toolslash = {
			{ id = "http://www.roblox.com/asset/?id=522635514", weight = 10 } 
		},
		toollunge = {
			{ id = "http://www.roblox.com/asset/?id=522638767", weight = 10 } 
		},
		wave = {
			{ id = "http://www.roblox.com/asset/?id=507770239", weight = 10 } 
		},
		point = {
			{ id = "http://www.roblox.com/asset/?id=507770453", weight = 10 } 
		},
		dance = {
			{ id = "http://www.roblox.com/asset/?id=507771019", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507771955", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507772104", weight = 10 } 
		},
		dance2 = {
			{ id = "http://www.roblox.com/asset/?id=507776043", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507776720", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507776879", weight = 10 } 
		},
		dance3 = {
			{ id = "http://www.roblox.com/asset/?id=507777268", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507777451", weight = 10 }, 
			{ id = "http://www.roblox.com/asset/?id=507777623", weight = 10 } 
		},
		laugh = {
			{ id = "http://www.roblox.com/asset/?id=507770818", weight = 10 } 
		},
		cheer = {
			{ id = "http://www.roblox.com/asset/?id=507770677", weight = 10 } 
		},
	}

	local emoteNames = { wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

	math.randomseed(tick())

	local function findExistingAnimationInSet(set, anim)
		if set == nil or anim == nil then
			return 0
		end

		for idx = 1, set.count, 1 do 
			if set[idx].anim.AnimationId == anim.AnimationId then
				return idx
			end
		end

		return 0
	end

	local function configureAnimationSet(name, fileList)
		if (animTable[name] ~= nil) then
			for _, connection in pairs(animTable[name].connections) do
				connection:disconnect()
			end
		end
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0	
		animTable[name].connections = {}

		local allowCustomAnimations = true

		local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
		if not success then
			allowCustomAnimations = true
		end

		local config = Script:FindFirstChild(name)
		if (allowCustomAnimations and config ~= nil) then
			table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
			table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))

			local idx = 0
			for _, childPart in pairs(config:GetChildren()) do
				if (childPart:IsA("Animation")) then
					local newWeight = 1
					local weightObject = childPart:FindFirstChild("Weight")
					if (weightObject ~= nil) then
						newWeight = weightObject.Value
					end
					animTable[name].count = animTable[name].count + 1
					idx = animTable[name].count
					animTable[name][idx] = {}
					animTable[name][idx].anim = childPart
					animTable[name][idx].weight = newWeight
					animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
					table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
					table.insert(animTable[name].connections, childPart.ChildAdded:connect(function(property) configureAnimationSet(name, fileList) end))
					table.insert(animTable[name].connections, childPart.ChildRemoved:connect(function(property) configureAnimationSet(name, fileList) end))
				end
			end
		end

		if (animTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
			end
		end

		for i, animType in pairs(animTable) do
			for idx = 1, animType.count, 1 do
				if PreloadedAnims[animType[idx].anim.AnimationId] == nil then
					pcall(function()
						PetHumanoid:LoadAnimation(animType[idx].anim)
					end)
					PreloadedAnims[animType[idx].anim.AnimationId] = true
				end				
			end
		end
	end

	local function configureAnimationSetOld(name, fileList)
		if (animTable[name] ~= nil) then
			for _, connection in pairs(animTable[name].connections) do
				connection:disconnect()
			end
		end
		animTable[name] = {}
		animTable[name].count = 0
		animTable[name].totalWeight = 0	
		animTable[name].connections = {}

		local allowCustomAnimations = true

		local success, msg = pcall(function() allowCustomAnimations = game:GetService("StarterPlayer").AllowCustomAnimations end)
		if not success then
			allowCustomAnimations = true
		end

		local config = Script:FindFirstChild(name)
		if (allowCustomAnimations and config ~= nil) then
			table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
			table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
			local idx = 1
			for _, childPart in pairs(config:GetChildren()) do
				if (childPart:IsA("Animation")) then
					table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
					animTable[name][idx] = {}
					animTable[name][idx].anim = childPart
					local weightObject = childPart:FindFirstChild("Weight")
					if (weightObject == nil) then
						animTable[name][idx].weight = 1
					else
						animTable[name][idx].weight = weightObject.Value
					end
					animTable[name].count = animTable[name].count + 1
					animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
					idx = idx + 1
				end
			end
		end

		if (animTable[name].count <= 0) then
			for idx, anim in pairs(fileList) do
				animTable[name][idx] = {}
				animTable[name][idx].anim = Instance.new("Animation")
				animTable[name][idx].anim.Name = name
				animTable[name][idx].anim.AnimationId = anim.id
				animTable[name][idx].weight = anim.weight
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
				-- print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
			end
		end

		for i, animType in pairs(animTable) do
			for idx = 1, animType.count, 1 do
				pcall(function()
					PetHumanoid:LoadAnimation(animType[idx].anim)
				end)
			end
		end
	end

	local function scriptChildModified(child)
		local fileList = animNames[child.Name]
		if (fileList ~= nil) then
			configureAnimationSet(child.Name, fileList)
		end	
	end

	Script.ChildAdded:connect(scriptChildModified)
	Script.ChildRemoved:connect(scriptChildModified)

	local animator = if PetHumanoid then PetHumanoid:FindFirstChildOfClass("Animator") else nil
	if animator then
		local animTracks = animator:GetPlayingAnimationTracks()
		for i,track in ipairs(animTracks) do
			track:Stop(0)
			track:Destroy()
		end
	end

	for name, fileList in pairs(animNames) do 
		configureAnimationSet(name, fileList)
	end	

	local toolAnim = "None"
	local toolAnimTime = 0

	local jumpAnimTime = 0
	local jumpAnimDuration = 0.31

	local toolTransitionTime = 0.1
	local fallTransitionTime = 0.2

	local currentlyPlayingEmote = false

	local function stopAllAnimations()
		local oldAnim = currentAnim

		if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
			oldAnim = "idle"
		end

		if currentlyPlayingEmote then
			oldAnim = "idle"
			currentlyPlayingEmote = false
		end

		currentAnim = ""
		currentAnimInstance = nil
		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop()
			currentAnimTrack:Destroy()
			currentAnimTrack = nil
		end

		if (runAnimKeyframeHandler ~= nil) then
			runAnimKeyframeHandler:disconnect()
		end

		if (runAnimTrack ~= nil) then
			runAnimTrack:Stop()
			runAnimTrack:Destroy()
			runAnimTrack = nil
		end

		return oldAnim
	end

	local function getHeightScale()
		if PetHumanoid then
			if not PetHumanoid.AutomaticScalingEnabled then
				return getRigScale()
			end

			local scale = PetHumanoid.HipHeight / HumanoidHipHeight
			if AnimationSpeedDampeningObject == nil then
				AnimationSpeedDampeningObject = Script:FindFirstChild("ScaleDampeningPercent")
			end
			if AnimationSpeedDampeningObject ~= nil then
				scale = 1 + (PetHumanoid.HipHeight - HumanoidHipHeight) * AnimationSpeedDampeningObject.Value / HumanoidHipHeight
			end
			return scale
		end	
		return getRigScale()
	end

	local function rootMotionCompensation(speed)
		local speedScaled = speed * 1.25
		local heightScale = getHeightScale()
		local runSpeed = speedScaled / heightScale
		return runSpeed
	end

	local smallButNotZero = 0.0001
	local function setRunSpeed(speed)
		local normalizedWalkSpeed = 0.5
		local normalizedRunSpeed  = 1
		local runSpeed = rootMotionCompensation(speed)

		local walkAnimationWeight = smallButNotZero
		local runAnimationWeight = smallButNotZero
		local timeWarp = 1

		if runSpeed <= normalizedWalkSpeed then
			walkAnimationWeight = 1
			timeWarp = runSpeed/normalizedWalkSpeed
		elseif runSpeed < normalizedRunSpeed then
			local fadeInRun = (runSpeed - normalizedWalkSpeed)/(normalizedRunSpeed - normalizedWalkSpeed)
			walkAnimationWeight = 1 - fadeInRun
			runAnimationWeight  = fadeInRun
		else
			timeWarp = runSpeed/normalizedRunSpeed
			runAnimationWeight = 1
		end
		currentAnimTrack:AdjustWeight(walkAnimationWeight)
		runAnimTrack:AdjustWeight(runAnimationWeight)
		currentAnimTrack:AdjustSpeed(timeWarp)
		runAnimTrack:AdjustSpeed(timeWarp)
	end

	local function setAnimationSpeed(speed)
		if currentAnim == "walk" then
			setRunSpeed(speed)
		else
			if speed ~= currentAnimSpeed then
				currentAnimSpeed = speed
				currentAnimTrack:AdjustSpeed(currentAnimSpeed)
			end
		end
	end

	local playAnimation = nil

	local function keyFrameReachedFunc(frameName)
		if (frameName == "End") then
			if currentAnim == "walk" then
				if userNoUpdateOnLoop == true then
					if runAnimTrack.Looped ~= true then
						runAnimTrack.TimePosition = 0.0
					end
					if currentAnimTrack.Looped ~= true then
						currentAnimTrack.TimePosition = 0.0
					end
				else
					runAnimTrack.TimePosition = 0.0
					currentAnimTrack.TimePosition = 0.0
				end
			else
				local repeatAnim = currentAnim
				if (emoteNames[repeatAnim] ~= nil and emoteNames[repeatAnim] == false) then
					repeatAnim = "idle"
				end

				if currentlyPlayingEmote then
					if currentAnimTrack.Looped then
						return
					end

					repeatAnim = "idle"
					currentlyPlayingEmote = false
				end

				local animSpeed = currentAnimSpeed
				playAnimation(repeatAnim, 0.15, PetHumanoid)
				setAnimationSpeed(animSpeed)
			end
		end
	end

	local function rollAnimation(animName)
		local roll = math.random(1, animTable[animName].totalWeight) 
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
		return idx
	end

	local function switchToAnim(anim, animName, transitionTime, humanoid)
		if (anim ~= currentAnimInstance) then

			if (currentAnimTrack ~= nil) then
				currentAnimTrack:Stop(transitionTime)
				currentAnimTrack:Destroy()
			end

			if (runAnimTrack ~= nil) then
				runAnimTrack:Stop(transitionTime)
				runAnimTrack:Destroy()
				if userNoUpdateOnLoop == true then
					runAnimTrack = nil
				end
			end

			currentAnimSpeed = 1.0

			pcall(function()
				currentAnimTrack = humanoid:LoadAnimation(anim)
			end)
			currentAnimTrack.Priority = Enum.AnimationPriority.Core

			currentAnimTrack:Play(transitionTime)
			currentAnim = animName
			currentAnimInstance = anim

			if (currentAnimKeyframeHandler ~= nil) then
				currentAnimKeyframeHandler:disconnect()
			end
			currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)

			if animName == "walk" then
				local runAnimName = "run"
				local runIdx = rollAnimation(runAnimName)

				pcall(function()
					runAnimTrack = humanoid:LoadAnimation(animTable[runAnimName][runIdx].anim)
				end)
				runAnimTrack.Priority = Enum.AnimationPriority.Core
				runAnimTrack:Play(transitionTime)		

				if (runAnimKeyframeHandler ~= nil) then
					runAnimKeyframeHandler:disconnect()
				end
				runAnimKeyframeHandler = runAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)	
			end
		end
	end

	playAnimation = function(animName, transitionTime, humanoid) 	
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		switchToAnim(anim, animName, transitionTime, humanoid)
		currentlyPlayingEmote = false
	end

	local function playEmote(emoteAnim, transitionTime, humanoid)
		switchToAnim(emoteAnim, emoteAnim.Name, transitionTime, humanoid)
		currentlyPlayingEmote = true
	end

	local toolAnimName = ""
	local toolAnimTrack = nil
	local toolAnimInstance = nil
	local currentToolAnimKeyframeHandler = nil

	local playToolAnimation = nil

	local function toolKeyFrameReachedFunc(frameName)
		if (frameName == "End") then
			playToolAnimation(toolAnimName, 0.0, PetHumanoid)
		end
	end


	playToolAnimation = function(animName, transitionTime, humanoid, priority)	 		
		local idx = rollAnimation(animName)
		local anim = animTable[animName][idx].anim

		if (toolAnimInstance ~= anim) then

			if (toolAnimTrack ~= nil) then
				toolAnimTrack:Stop()
				toolAnimTrack:Destroy()
				transitionTime = 0
			end

			pcall(function()
				toolAnimTrack = humanoid:LoadAnimation(anim)
			end)
			if priority then
				toolAnimTrack.Priority = priority
			end

			toolAnimTrack:Play(transitionTime)
			toolAnimName = animName
			toolAnimInstance = anim

			currentToolAnimKeyframeHandler = toolAnimTrack.KeyframeReached:connect(toolKeyFrameReachedFunc)
		end
	end

	local function stopToolAnimations()
		local oldAnim = toolAnimName

		if (currentToolAnimKeyframeHandler ~= nil) then
			currentToolAnimKeyframeHandler:disconnect()
		end

		toolAnimName = ""
		toolAnimInstance = nil
		if (toolAnimTrack ~= nil) then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			toolAnimTrack = nil
		end

		return oldAnim
	end

	local function onRunning(speed)
		local heightScale = if userAnimateScaleRun then getHeightScale() else 1

		local movedDuringEmote = currentlyPlayingEmote and PetHumanoid.MoveDirection == Vector3.new(0, 0, 0)
		local speedThreshold = movedDuringEmote and (PetHumanoid.WalkSpeed / heightScale) or 0.75
		if speed > speedThreshold * heightScale then
			local scale = 16.0
			playAnimation("walk", 0.2, PetHumanoid)
			setAnimationSpeed(speed / scale)
			pose = "Running"
		else
			if emoteNames[currentAnim] == nil and not currentlyPlayingEmote then
				playAnimation("idle", 0.2, PetHumanoid)
				pose = "Standing"
			end
		end
	end

	local function onDied()
		pose = "Dead"
	end

	local function onJumping()
		playAnimation("jump", 0.1, PetHumanoid)
		jumpAnimTime = jumpAnimDuration
		pose = "Jumping"
	end

	local function onClimbing(speed)
		if userAnimateScaleRun then
			speed /= getHeightScale()
		end
		local scale = 5.0
		playAnimation("climb", 0.1, PetHumanoid)
		setAnimationSpeed(speed / scale)
		pose = "Climbing"
	end

	local function onGettingUp()
		pose = "GettingUp"
	end

	local function onFreeFall()
		if (jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, PetHumanoid)
		end
		pose = "FreeFall"
	end

	local function onFallingDown()
		pose = "FallingDown"
	end

	local function onSeated()
		pose = "Seated"
	end

	local function onPlatformStanding()
		pose = "PlatformStanding"
	end

	local function onSwimming(speed)
		if userAnimateScaleRun then
			speed /= getHeightScale()
		end
		if speed > 1.00 then
			local scale = 10.0
			playAnimation("swim", 0.4, PetHumanoid)
			setAnimationSpeed(speed / scale)
			pose = "Swimming"
		else
			playAnimation("swimidle", 0.4, PetHumanoid)
			pose = "Standing"
		end
	end

	local function animateTool()
		if (toolAnim == "None") then
			playToolAnimation("toolnone", toolTransitionTime, PetHumanoid, Enum.AnimationPriority.Idle)
			return
		end

		if (toolAnim == "Slash") then
			playToolAnimation("toolslash", 0, PetHumanoid, Enum.AnimationPriority.Action)
			return
		end

		if (toolAnim == "Lunge") then
			playToolAnimation("toollunge", 0, PetHumanoid, Enum.AnimationPriority.Action)
			return
		end
	end

	local function getToolAnim(tool)
		for _, c in ipairs(tool:GetChildren()) do
			if c.Name == "toolanim" and c.className == "StringValue" then
				return c
			end
		end
		return nil
	end

	local lastTick = 0

	local function stepAnimate(currentTime)
		local amplitude = 1
		local frequency = 1
		local deltaTime = currentTime - lastTick
		lastTick = currentTime

		local climbFudge = 0
		local setAngles = false

		if (jumpAnimTime > 0) then
			jumpAnimTime = jumpAnimTime - deltaTime
		end

		if (pose == "FreeFall" and jumpAnimTime <= 0) then
			playAnimation("fall", fallTransitionTime, PetHumanoid)
		elseif (pose == "Seated") then
			playAnimation("sit", 0.5, PetHumanoid)
			return
		elseif (pose == "Running") then
			playAnimation("walk", 0.2, PetHumanoid)
		elseif (pose == "Dead" or pose == "GettingUp" or pose == "FallingDown" or pose == "Seated" or pose == "PlatformStanding") then
			stopAllAnimations()
			amplitude = 0.1
			frequency = 1
			setAngles = true
		end

		local tool = character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("Handle") then
			local animStringValueObject = getToolAnim(tool)

			if animStringValueObject then
				toolAnim = animStringValueObject.Value
				animStringValueObject.Parent = nil
				toolAnimTime = currentTime + .3
			end

			if currentTime > toolAnimTime then
				toolAnimTime = 0
				toolAnim = "None"
			end

			animateTool()		
		else
			stopToolAnimations()
			toolAnim = "None"
			toolAnimInstance = nil
			toolAnimTime = 0
		end
	end

	PetHumanoid.Died:connect(onDied)
	PetHumanoid.Running:connect(onRunning)
	PetHumanoid.Jumping:connect(onJumping)
	PetHumanoid.Climbing:connect(onClimbing)
	PetHumanoid.GettingUp:connect(onGettingUp)
	PetHumanoid.FreeFalling:connect(onFreeFall)
	PetHumanoid.FallingDown:connect(onFallingDown)
	PetHumanoid.Seated:connect(onSeated)
	PetHumanoid.PlatformStanding:connect(onPlatformStanding)
	PetHumanoid.Swimming:connect(onSwimming)

	player.Chatted:connect(function(msg)
		local emote = ""
		if (string.sub(msg, 1, 3) == "/e ") then
			emote = string.sub(msg, 4)
		elseif (string.sub(msg, 1, 7) == "/emote ") then
			emote = string.sub(msg, 8)
		end

		if (pose == "Standing" and emoteNames[emote] ~= nil) then
			playAnimation(emote, EMOTE_TRANSITION_TIME, PetHumanoid)
		end
	end)

	Script:WaitForChild("PlayEmote").OnInvoke = function(emote)
		if pose ~= "Standing" then
			return
		end

		if emoteNames[emote] ~= nil then
			playAnimation(emote, EMOTE_TRANSITION_TIME, PetHumanoid)

			return true, currentAnimTrack
		elseif typeof(emote) == "Instance" and emote:IsA("Animation") then
			playEmote(emote, EMOTE_TRANSITION_TIME, PetHumanoid)

			return true, currentAnimTrack
		end

		return false
	end

	if character.Parent ~= nil then
		playAnimation("idle", 0.1, PetHumanoid)
		pose = "Standing"
	end

	while character.Parent ~= nil do
		local _, currentGameTime = wait(0.1)
		stepAnimate(currentGameTime)
	end
end

return CharacterFunctions
