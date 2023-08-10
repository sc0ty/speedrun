-- Script written by Zolw Michal -- https://github.com/sc0ty --

-------------------
-- PERSONAL BEST --
-------------------
-- Put here your timings for each level.
-- These are number of frames displayed in square brackets at the end of each split line.
personalBest = {
	3437,
	7812,
	13883,
	21793,
	29653,
	34941,
	40629,
	45106
}

-------------------
-- CONFIGURATION --
-------------------
placement = {
	timer = {x=205, y=9},
	split = {x=100, y=221}
}

----------
-- CODE --
----------
state = {startFrame=-1, frame=0, screenType=-1, oldScreenType=-1, stage=1}
runs = {}
lastStageText = nil
lastStageColor = nil

function everything()
	state.oldScreenType = state.screenType
	state.screenType = memory.readbyte(0x002C)
	state.stage = memory.readbyte(0x0030) + 1

	if #runs < 8 then
		-- during gameplay --
		updateState()
	--[[else
		-- game finished - check for reset --
		--state.stage = memory.readbyte(0x0030) + 1
		if state.stage < 8 then
			reset()
		end]]--
	end

	if state.screenType == 0 and state.oldScreenType ~= 0 and state.stage == 1 then
		reset()
	end

	-- draw frame counter --
	if state.startFrame >= 0 then
		frame = state.frame - state.startFrame
		if frame >= 0 then
			gui.text(placement.timer.x, placement.timer.y, formatTime(frame))
		end
	end

	-- draw split --
	st = state.screenType
	if (st >= 0 and st <= 2) or st == 5  or st == 6 or state.stage > 8 or isPaused() then
		drawFullSplit()
	elseif lastStageText ~= nil then
		gui.text(placement.split.x, placement.split.y, lastStageText, lastStageColor)
	end
end

function updateState()
	state.frame = movie.framecount()

	-- start timer --
	if state.stage == 1 and state.screenType == 4 and state.oldScreenType == 3 and isDemoMode() == false then
		reset()
		state.startFrame = state.frame
		print("Start frame: ", state.startFrame)
	end

	-- end stage --
	if state.startFrame >= 0 and state.screenType == 9 and state.oldScreenType ~= 9 then
		cur = state.frame - state.startFrame
		pb = personalBest[state.stage] or 0
		lastStageText = getLineText(cur, pb, state.stage)
		lastStageColor = getLineColor(cur, pb)
		runs[state.stage] = {cur=cur, pb=pb, text=lastStageText, color=lastStageColor}
		print(string.format("Stage " .. lastStageText))
	end

	-- debug logs --
	--[[
	if state.screenType ~= state.oldScreenType then
		print(state.frame, state.screenType, state)
	end
	]]--
end

function reset()
	print("Reset")
	state.startFrame = -1
	runs = {}
	lastStageText = nil
	lastStageColor = nil
end

function drawFullSplit()
	y = placement.split.y - 9*(#runs - 1)
	for i = 1, #runs do
		run = runs[i]
		gui.text(placement.split.x, y, run.text, run.color)
		y = y + 9
	end
end

function getLineText(cur, pb, no)
	return string.format("%d. %s %s [%d]", no, formatTime(cur), formatDelta(cur, pb), cur)
end

function getLineColor(cur, pb, no)
	if pb == nil or pb == 0 or pb == cur then
		return "white"
	elseif cur < pb then
		return "green"
	elseif cur > pb then
		return "red"
	else
		return "white"
	end
end

function isDemoMode()
	return memory.readbyte(0x001C) == 1 -- 0 = normal, 1 = demo
end

function isPaused()
	return memory.readbyte(0x0025) == 1
end

nesClockSpeed = 39375000 / 655171 -- ~60.098, the "true clock speed" of the NES

function formatTime(frames)
	totalSeconds = frames / nesClockSpeed
	secs = totalSeconds % 60
	mins = math.floor(totalSeconds / 60) % 60
	return string.format("%02d:%05.2f", mins, secs)
end

function formatDelta(cur, pb)
	if pb ~= nil and pb ~= 0 then
		frames = cur - pb
		f = math.abs(frames)
		totalSeconds = f / nesClockSpeed
		secs = totalSeconds % 60
		mins = math.floor(totalSeconds / 60) % 60
		if frames > 0 then
			sign = "+"
		elseif frames < 0 then
			sign = "-"
		else
			sign = " "
		end
		if mins > 0 then
			return string.format("%s%d:%05.2f", sign, mins, secs)
		else
			return string.format("%s%.2f", sign, secs)
		end
	else
		return ""
	end
end


gui.register(everything)

while true do
	emu.frameadvance()
end