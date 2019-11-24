--
-- SUPER MARIO BROS AI
--    Genetic Algo
-- By: Miles Fertel
--

population = {} --population container
backgroundColor = 0x2C3D72000 --red color
MAX_FRAMES = 2500 --frames to pass the game
POPULATION_SIZE = 25 --size of individuals in the generation
MUTATE_JUMP = 0.01
MUTATE_B = 0.01
MUTATE_RIGHT = 0.01
FILE_NAME = "SMB1-1.state" --game file saved by starting the level
ROM_NAME = "mario_rom.nes"
JUMP_WEIGHT = 0.50
B_WEIGHT = 0.50 --probability of dashing
RIGHT_WEIGHT = 0.50 --probability of moving to the right


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
	for count = 0, POPULATION_SIZE do
		population[count] = generateIndividualDNA()
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

	if population[0].fitness > maxFitness then
		maxFitness = population[0].fitness
		writeIndiv(population[0], "mario" .. maxFitness)
	end

	console.writeline("Max Fitness: " .. maxFitness);

	for i = 0, POPULATION_SIZE do
		newPopulation[i] = population[math.random(TOP_N)]
	end

	for i = 0, POPULATION_SIZE do
		newPopulation[i] = clone(newPopulation[i])
	end

	population = newPopulation --replacing new population with a new one

end

function drawGui(index, generation, highestFit, highestSpeed)
	--Draw GUI Heads Up display
	gui.drawBox(0, 0, 300, 45, backgroundColor, backgroundColor)
	gui.drawText(0, 10, "Generation No." .. generation .. "--Individual No." .. index, 0xFFFFFFFF, 8)
	gui.drawText(0, 20, "Fitness =" .. population[index].fitness .. "in" .. population[index].frameNumber .. "frames", 0xFFFFFFFF, 8)
	gui.drawText(0, 30, "Top Fitness =" .. maxFitness, 0xFFFFFFFF, 8)
end

console.writeline("Generating random population.")
generateRandomPopulation()
console.writeline("Ready. Playing with first generation.")
generation = 0

MAX_SAME = 100
while true do --do forever
	generation = generation + 1
	for index = 0, POPULATION_SIZE do --for each individual in the population
		local sameCount = 0
		local oldPos = 0
		savestate.load(FILE_NAME) --load the start of the level

		population[index].frameNumber = 0
		while true do --play with the individual
			local xPos = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86) --mario X position in level
			if population[index].frameNumber == MAX_FRAMES or sameCount == MAX_SAME then
				break
			end

			if math.abs(xPos - oldPos) == 0 then
				sameCount = sameCount + 1
			else
				sameCount = 0
			end
			
			if population[index].frameNumber % 10 == 0 then
				oldPos = xPos
			end

			population[index].fitness = xPos
			population[index].fitness = population[index].fitness / 20 --normalizing by dividing by 50
			population[index].fitness = math.floor(population[index].fitness) --rounded to an int
			population[index].frameNumber = population[index].frameNumber + 1 --adding ++ 1 to the frame
			
			-- drawGui(index, generation, highestFit, highestSpeed)

			controller = {}
			controller["P1 A"] = population[index].frames[population[index].frameNumber].a
			controller["P1 B"] = population[index].frames[population[index].frameNumber].b
			controller["P1 Right"] = population[index].frames[population[index].frameNumber].right

			joypad.set(controller) --api to press use the control

			emu.frameadvance() --Api advance frame in the game

			if memory.readbyte(0x000E) == 0x06 or memory.readbyte(0x000E) == 0x0b then
				break --if mario dies restart game with next individual
			end
		end

		console.writeline("Fitness reached:" .. index .. " > " .. population[index].fitness) --log finess reached
	end

	console.writeline("")
	console.writeline("Evolving new generation." .. "(" .. generation + 1 .. ")")
	evolvePopulation()

end