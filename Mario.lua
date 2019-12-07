--
-- SUPER MARIO BROS AI
--    Genetic Algo
-- By: Miles Fertel
--

MarioLib = require("MarioLib")
GeneticsLib = require("GeneLib")
console.writeline(MarioLib.distances)

population = {} --population container
backgroundColor = 0x2C3D72000 --red color
MAX_FRAMES = 50000 --frames to pass the game
POPULATION_SIZE = 50 --size of individuals in the generation
MUTATE_JUMP = 0.01
MUTATE_B = 0.01
MUTATE_RIGHT = 0.01
FILE_NAME = "SMB1-1.state" --game file saved by starting the level
ROM_NAME = "mario_rom.nes"
JUMP_WEIGHT = 0.50
B_WEIGHT = 0.50 --probability of dashing
RIGHT_WEIGHT = 0.50 --probability of moving to the right

function generatePerfectIndividual()
	local individual = {}
	individual.frames = {}

	local file = io.open("mario163", "rb")
	local data = file:read("*a")
	lines = data:gmatch("[^\r\n]+")
	local count = 0
	for line in lines do 
		local words = line:gmatch("%w+")
		count = tonumber(words())
		individual.frames[count] = {}
		individual.frames[count].a = words() == "true"
		individual.frames[count].b = words() == "true"
		individual.frames[count].right = words() == "true"
	end
	for i = count + 1, MAX_FRAMES do
		individual.frames[i] = {}
		individual.frames[i].a = math.random() < JUMP_WEIGHT and true or false
		individual.frames[i].b = math.random() < B_WEIGHT and true or false
		individual.frames[i].right = math.random() < RIGHT_WEIGHT and true or false
	end
	return clone(individual, true)
end

function generateIndividualDNA() --generate DNA from a random individual
	local individual = {}
	individual.frames = {}

	for count = 0, MAX_FRAMES do
		individual.frames[count] = {}
		individual.frames[count].a = math.random() < JUMP_WEIGHT and true or false
		individual.frames[count].b = math.random() < B_WEIGHT and true or false
		individual.frames[count].right = math.random() < RIGHT_WEIGHT and true or false
	end
	return individual --return the individual's DNA
end

function generateRandomPopulation() --generate first random population
	for count = 1, POPULATION_SIZE do
		-- population[count] = generateIndividualDNA()
		population[count] = generatePerfectIndividual()
	end
end


function clone(indiv, mutate) --slightly change the DNA of an individual
	local newIndiv = {}
	newIndiv.frames = {}

	for count = 0, MAX_FRAMES do
		newIndiv.frames[count] = {}
		newIndiv.frames[count].a = math.random() < MUTATE_JUMP and mutate and not indiv.frames[count].a or indiv.frames[count].a
		newIndiv.frames[count].b = math.random() < MUTATE_B and mutate and not indiv.frames[count].b or indiv.frames[count].b
		newIndiv.frames[count].right = math.random() < MUTATE_RIGHT and mutate and not indiv.frames[count].right or indiv.frames[count].right
	end

	return newIndiv
end

function writeIndiv(indiv, filename)
	local file, err = io.open(filename, "wb")
	if err then return err end
	for count = 0, MAX_FRAMES do
		file:write(count ..  " " .. tostring(indiv.frames[count].a) ..  " " .. tostring(indiv.frames[count].b) .. " " .. tostring(indiv.frames[count].right) .. "\n")
	end
      	file:close()
end

function compare(a, b)
	return a.fitness > b.fitness
end

TOP_N = 2
maxFitness = 0
function evolvePopulation()
	local newPopulation = {}

	table.sort(population, compare)

	if population[1].fitness > maxFitness then
		maxFitness = population[1].fitness
		if maxFitness > 1000 then
			writeIndiv(population[1], "mario" .. maxFitness)
		end
	end

	console.writeline("Max Fitness: " .. maxFitness)

	for i = 1, POPULATION_SIZE do
		local prob = population[1].fitness / (population[1].fitness + population[2].fitness)
		newPopulation[i] = population[math.random() < prob and 1 or 2]
	end

	local n = 3
	for i = 1, n do
		newPopulation[i] = clone(newPopulation[i], false)
	end

	for i = n + 1, POPULATION_SIZE do
		newPopulation[i] = clone(newPopulation[i], true)
	end

	population = newPopulation --replacing new population with a new one

end

function drawGui(index, generation)
	--Draw GUI Heads Up display
	gui.drawBox(0, 0, 300, 45, backgroundColor, backgroundColor)
	gui.drawText(0, 10, "Generation No." .. generation .. "--Individual No." .. index, 0xFFFFFFFF, 8)
	gui.drawText(0, 20, "Fitness =" .. population[index].fitness .. "in" .. population[index].frameNumber .. "frames", 0xFFFFFFFF, 8)
end

function is_dead()
    local player_state = memory.readbyte(addr_player_state)
    local y_viewport = get_y_viewport()
    if (player_state == 0x06) or (player_state == 0x0b) or (y_viewport > 1) then
        return true
    else
        return false
    end
end

function getFitness(index)
	local indiv = population[index]
	local levelStr = indiv.curLevel
	local world = tonumber(levelStr:sub(1, 1)) - 1
	local level = tonumber(levelStr:sub(2, 2)) - 1
	local area = tonumber(levelStr:sub(3, 3)) - 1
	local fitness = world * 0x1000 + level * 0x100 + area * 0x10 + indiv.xPos / 10
	return math.floor(fitness)
end

console.writeline("Generating random population.")
generateRandomPopulation()
console.writeline("Ready. Playing with first generation.")
generation = 0

MAX_SAME = 100
while true do --do forever
	generation = generation + 1
	for index = 1, POPULATION_SIZE do --for each individual in the population
		local sameCount = 0
		local oldPos = 0
		savestate.load(FILE_NAME) --load the start of the level

		population[index].frameNumber = 0
		population[index].finished = false
		population[index].curLevel = get_level_str()
		population[index].xPos = 0
		while true do --play with the individual
			if not population[index].finished then
				-- Check if wasting time
				if population[index].frameNumber == MAX_FRAMES or sameCount >= MAX_SAME then
					-- console.writeline("MAX_FRAMES or MAX_SAME: " .. population[index].frameNumber .. " " .. sameCount)
					break
				end

				-- Makes sure we're not standing in one place
				population[index].xPos = get_x_pos()
				if math.abs(population[index].xPos - oldPos) == 0 then
					sameCount = sameCount + 1
				else
					sameCount = 0
				end
			
				-- Update every 10 frames
				if population[index].frameNumber % 10 == 0 then
					oldPos = population[index].xPos
				end

				population[index].fitness = getFitness(index)
				population[index].frameNumber = population[index].frameNumber + 1 --adding ++ 1 to the frame

				controller = {}
				controller["P1 A"] = population[index].frames[population[index].frameNumber].a
				controller["P1 B"] = population[index].frames[population[index].frameNumber].b
				controller["P1 Right"] = population[index].frames[population[index].frameNumber].right

				joypad.set(controller) --api to press use the control

				if is_dead() then
					break --if mario dies restart game with next individual
				end

				-- Check if we beat the level
				population[index].finished = finished() 
			else
				-- Wait for next level to start
				local curLevel = get_level_str()
				if curLevel ~= population[index].curLevel then
					population[index].curLevel = curLevel
					population[index].finished = false
				end
			end
			-- drawGui(index, generation, population[index].frameNumber)
			emu.frameadvance() --Api advance frame in the game
		end

		console.writeline("Fitness reached:" .. index .. " > " .. population[index].fitness) --log finess reached
	end

	console.writeline("")
	console.writeline("Evolving new generation." .. "(" .. generation + 1 .. ")")
	evolvePopulation()

end
