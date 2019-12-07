GeneLib = {}
GeneLib.__index = GeneLib

function GeneLib:createAlgo(settings)
	local gene = {}
    	setmetatable(gene, GeneLib)
	gene.settings = settings
    	gene.population = {}
	gene.maxFitness = -math.huge
    	return gene
end

function GeneLib:clone(indiv, mutate)
	local newIndiv = {}
	newIndiv.frames = {}

	local settings = self.settings
	for count = 0, settings.MAX_FRAMES do
		newIndiv.frames[count] = {}
		rates = settings.MUTATION_RATES
		for button in settings.BUTTONS do
			newIndiv.frames[count][button] = math.random() < rates[button] and mutate and not indiv.frames[count][button] or indiv.frames[count][button]
		end
	end

	return newIndiv
end

function GeneLib:generateIndividualDNA()
	local individual = {}
	individual.frames = {}

	local settings = self.settings
	for count = 0, settings.MAX_FRAMES do
		individual.frames[count] = {}
		rates = settings.BEGINNING_RATES
		for button in settings.BUTTONS do
			individual.frames[count][button] = math.random() < rates[button] and true or false
		end
	end
	return individual
end

function GeneLib:writeIndiv(indiv, filename)
	local file, err = io.open(filename, "wb")
	if err then return err end

	settings = self.settings
	for count = 0, settings.MAX_FRAMES do
		local s = ""
		for button in settings.buttons do
			s = s .. tostring(indiv.frames[count][button]) .. " "
		end
		s = s:sub(1, -2) .. "\n"
		file:write(s)
	end
      	file:close()
end

function GeneLib:generatePerfectIndividual()
	function getBestCheckPoint()

	end

	local individual = {}
	individual.frames = {}

	local settings = self.settings
	local file = io.open(self.GAME_NAME .. "163", "rb")
	local data = file:read("*a")
	local count = 0

	lines = data:gmatch("[^\r\n]+")
	for line in lines do
		local words = line:gmatch("%w+")
		count = tonumber(words())
		individual.frames[count] = {}
		for button in settings.buttons do
		    individual.frames[count][button] = words() == "true"
		end
	end
	for i = count + 1, settings.MAX_FRAMES do
		individual.frames[i] = {}
		rates = settings.BEGINNING_RATES
		for button in settings.buttons do
			individual.frames[i][button] = math.random() < rates[button] and true or false
		end
	end
	return self.clone(individual, true)
end
function GeneLib:generateRandomPopulation() --generate first random population
	local settings = self.settings
	for count = 1, settings.POPULATION_SIZE do
		if settings.CHECKPOINTED then
			-- self.population[count] = generatePerfectIndividual()
		else
			self.population[count] = self.generateIndividualDNA()
		end
	end
end

function GeneLib:evolvePopulation()
	local newPopulation = {}

	function compare(a, b)
		return a.fitness > b.fitness
	end
	table.sort(self.population, compare)

	local settings = self.settings
	local bestIndiv = self.population[1]
	if settings.CACHE and bestIndiv.fitness > self.maxFitness and bestIndiv.fitness > settings.CUTOFF then
		self.writeIndiv(bestIndiv, settings.GAME_NAME .. bestIndiv.fitness)
	end

	newPopulation[1] = bestIndiv
	for count = 2, settings.POPULATION_SIZE do
		newPopulation[count] = self.clone(self.population[count], true)
	end

	self.population = newPopulation
end

function GeneLib:runEvolution(generations)
	if not generations then
	    generations = math.huge
	end

	console.writeline("Generating random population.")
	self.generateRandomPopulation()
	console.writeline("Ready. Playing with first generation.")

	local settings = self.settings
	for generation = 1, generations do
	    for i = 1, settings.POPULATION_SIZE do
		local indiv = self.population[i]
		local res = self.runIndividual(indiv)
		console.writeline(indiv.fitness .. " " .. res.fitness)
		console.writeline("Fitness reached:" .. i .. " > " .. indiv.fitness) --log finess reached
	    end
	    console.writeline("")
	    console.writeline("Evolving new generation." .. "(" .. generation .. ")")
	    self.evolvePopulation()
	end
end


