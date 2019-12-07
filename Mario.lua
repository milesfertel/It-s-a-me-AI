--
-- SUPER MARIO BROS AI
--    Genetic Algo
-- By: Miles Fertel
--

MarioLib = require("MarioLib")
GeneLib = require("GeneLib")

settings = {
	-- Parameters
        MAX_FRAMES = 50000,
	POPULATION_SIZE = 50,
	BUTTONS = {
		"P1 A",
		"P1 B",
		"P1 Right"
        },
	BEGINNING_RATES = {
		["P1 A"] = 0.5,
		["P1 B"] = 0.5,
		["P1 Right"] = 0.5
	},
	MUTATION_RATES = {
		["P1 A"] = 0.01,
		["P1 B"] = 0.01,
		["P1 Right"] = 0.01
	},
        FILE_NAME = "SMB1-1.state",
	ROM_NAME = "mario_rom.nes",
        CACHE = true,
	GAME_NAME = "mario",
	MAX_SAME = 100, -- Number of frames with the same fitness
	CUTOFF = 163,
	CHECKPOINTED = false,

	-- Game specific functions
	runIndividual = run
}

function getFitness(indiv)
	local levelStr = indiv.curLevel
	local world = tonumber(levelStr:sub(1, 1)) - 1
	local level = tonumber(levelStr:sub(2, 2)) - 1
	local area = tonumber(levelStr:sub(3, 3)) - 1
	local fitness = world * 0x1000 + level * 0x100 + area * 0x10 + indiv.xPos / 10
	return math.floor(fitness)
end


function run(indiv)
	local sameCount = 0
	local oldPos = 0
	savestate.load(settings.FILE_NAME) --load the start of the level

	indiv.frameNumber = 0
	indiv.finished = false
	indiv.xPos = 0
	indiv.fitness = 0
	indiv.curLevel = MarioLib.getLevelStr()
	while true do --play with the individual
		if not indiv.finished then
			-- Check if wasting time
			if indiv.frameNumber == settings.MAX_FRAMES or sameCount >= indiv.MAX_SAME then
				console.writeline("MAX_FRAMES or MAX_SAME: " .. indiv.frameNumber .. " " .. sameCount)
				break
			end

			-- Makes sure we're not standing in one place
			indiv.xPos = MarioLib.getXPos()
			if math.abs(indiv.xPos - oldPos) == 0 then
				sameCount = sameCount + 1
			else
				sameCount = 0
			end

			-- Update every 10 frames
			if indiv.frameNumber % 10 == 0 then
				oldPos = indiv.xPos
			end

			indiv.fitness = getFitness(indiv)
			indiv.frameNumber = indiv.frameNumber + 1 --adding ++ 1 to the frame

			controller = {}
			for i, button in ipairs(setttings.BUTTONS) do
			    controller[button] = indiv.frames[indiv.frameNumber][button]
			end

			joypad.set(controller) --api to press use the control

			if MarioLib.isDead() then
				break --if mario dies restart game with next individual
			end

			-- Check if we beat the level
			indiv.finished = MarioLib.finished()
		else
			-- Wait for next level to start
			local curLevel = MarioLib.getLevelStr()
			if curLevel ~= indiv.curLevel then
				indiv.curLevel = curLevel
				indiv.finished = false
			end
		end
		-- drawGui(index, generation, population[index].frameNumber)
		emu.frameadvance() --Api advance frame in the game
	end
	return indiv
end

gene = GeneLib:createAlgo(settings)
gene:runEvolution(3)
