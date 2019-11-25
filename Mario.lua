--
-- SUPER MARIO BROS AI
--    Genetic Algo
-- By: Miles Fertel
--

distances = {}
distances["111"] = 3266    -- 1-1
distances["123"] = 3266    -- 1-2
distances["134"] = 2514    -- 1-3
distances["145"] = 2430    -- 1-4    
distances["211"] = 3298    -- 2-1
distances["223"] = 3266    -- 2-2
distances["234"] = 3682    -- 2-3
distances["245"] = 2430    -- 2-4    
distances["311"] = 3298    -- 3-1
distances["322"] = 3442    -- 3-2    
distances["333"] = 2498    -- 3-3
distances["344"] = 2430    -- 3-4
distances["411"] = 3698    -- 4-1
distances["423"] = 3266    -- 4-2
distances["434"] = 2434    -- 4-3
distances["445"] = 2942    -- 4-4
distances["511"] = 3282    -- 5-1
distances["522"] = 3298    -- 5-2
distances["533"] = 2514    -- 5-3
distances["544"] = 2429    -- 5-4
distances["611"] = 3106    -- 6-1
distances["622"] = 3554    -- 6-2
distances["633"] = 2754    -- 6-3
distances["644"] = 2429    -- 6-4
distances["711"] = 2962    -- 7-1
distances["723"] = 3266    -- 7-2
distances["734"] = 3682    -- 7-3
distances["745"] = 3453    -- 7-4
distances["811"] = 6114    -- 8-1
distances["822"] = 3554    -- 8-2
distances["833"] = 3554    -- 8-3
distances["844"] = 4989    -- 8-4

addr_world = 0x075f
addr_level = 0x075c
addr_area = 0x0760
addr_player_state = 0x000e
addr_y_viewport = 0x00b5
addr_curr_page = 0x6d
addr_curr_x = 0x86

-- get_world_number - Returns current world number (1 to 8)
function get_world_number()
	return memory.readbyte(addr_world) + 1
end

-- get_level_number - Returns current level number (1 to 4)
function get_level_number()
	return memory.readbyte(addr_level) + 1
end

-- get_area_number - Returns current area number (1 to 5)
function get_area_number()
	return memory.readbyte(addr_area) + 1
end

function get_y_viewport()
    	return memory.readbyte(addr_y_viewport);
end

function get_x_pos()
	return memory.readbyte(addr_curr_page) * 0x100 + memory.readbyte(addr_curr_x)
end

function get_level_str()
	return tostring(get_world_number()) .. tostring(get_level_number()) .. tostring(get_area_number())
end

function get_max_dist()
	return distances[get_level_str()] or 0
end

function finished()
	local max_distance = get_max_dist()
	local curr_x_position = get_x_pos()
	if ((curr_x_position >= max_distance - 15) and (curr_x_position <= max_distance)) then
		return true
	else 
		return false
	end
end

population = {} --population container
backgroundColor = 0x2C3D72000 --red color
MAX_FRAMES = 10000 --frames to pass the game
POPULATION_SIZE = 35 --size of individuals in the generation
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
	return clone(individual)
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


function clone(indiv) --slightly change the DNA of an individual
	local newIndiv = {}
	newIndiv.frames = {}

	for count = 0, MAX_FRAMES do
		newIndiv.frames[count] = {}
		newIndiv.frames[count].a = math.random() < MUTATE_JUMP and not indiv.frames[count].a or indiv.frames[count].a
		newIndiv.frames[count].b = math.random() < MUTATE_B and not indiv.frames[count].b or indiv.frames[count].b
		newIndiv.frames[count].right = math.random() < MUTATE_RIGHT and not indiv.frames[count].right or indiv.frames[count].right
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
		newPopulation[i] = population[math.random(TOP_N)]
	end

	for i = 1, POPULATION_SIZE do
		newPopulation[i] = clone(newPopulation[i])
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
