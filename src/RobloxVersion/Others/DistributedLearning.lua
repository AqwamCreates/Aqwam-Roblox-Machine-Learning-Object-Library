local ModelParametersMerger = require(script.Parent.Parent.Others.ModelParametersMerger)

DistributedLearning = {}

DistributedLearning.__index = DistributedLearning

local defaultTotalNumberOfReinforcementsToUpdateMainModel = 100

function DistributedLearning.new(totalNumberOfReinforcementsToUpdateMainModel)
	
	local NewDistributedLearning = {}
	
	setmetatable(NewDistributedLearning, DistributedLearning)
	
	NewDistributedLearning.totalNumberOfReinforcementsToUpdateMainModel = totalNumberOfReinforcementsToUpdateMainModel or defaultTotalNumberOfReinforcementsToUpdateMainModel
	
	NewDistributedLearning.currentTotalNumberOfReinforcementsToUpdateMainModel = 0
	
	NewDistributedLearning.ModelArray = {}
	
	NewDistributedLearning.IsDistributedLearningRunning = false
	
	NewDistributedLearning.ModelParametersMerger = ModelParametersMerger.new(nil, nil, "Average")
	
	return NewDistributedLearning
	
end

function DistributedLearning:setParameters(totalNumberOfReinforcementsToUpdateMainModel)
	
	self.totalNumberOfReinforcementsToUpdateMainModel = totalNumberOfReinforcementsToUpdateMainModel or defaultTotalNumberOfReinforcementsToUpdateMainModel
	
end

function DistributedLearning:addModel(Model)
	
	if not Model then error("Model is empty!") end

	table.insert(self.ModelArray, Model)
	
end

function DistributedLearning:reinforce(currentFeatureVector, rewardValue, returnOriginalOutput, modelNumber)
	
	local Model = self.ModelArray[modelNumber]
	
	return Model:reinforce(currentFeatureVector, rewardValue, returnOriginalOutput)
	
end

function DistributedLearning:train(featureVector, labelVector, modelNumber)

	local Model = self.ModelArray[modelNumber]

	return Model:train(featureVector, labelVector)

end

function DistributedLearning:predict(featureVector, returnOriginalOutput, modelNumber)

	local Model = self.ModelArray[modelNumber]

	return Model:predict(featureVector, returnOriginalOutput)

end

function DistributedLearning:setMainModelParameters(MainModelParameters)
	
	self.MainModelParameters = MainModelParameters
	
end

function DistributedLearning:getMainModelParameters()
	
	return self.MainModelParameters
	
end

function  DistributedLearning:currentTotalNumberOfReinforcementsToUpdateMainModel()
	
	return self.currentTotalNumberOfReinforcementsToUpdateMainModel
	
end

function DistributedLearning:start()
	
	if (self.IsDistributedLearningRunning == true) then error("The model is already running!") end
	
	self.IsDistributedLearningRunning = true
	
	local trainCoroutine = coroutine.create(function()

		repeat
			
			task.wait()
			
			if (self.currentTotalNumberOfReinforcementsToUpdateMainModel < self.totalNumberOfReinforcementsToUpdateMainModel) then continue end
			
			self.currentTotalNumberOfReinforcementsToUpdateMainModel = 0
			
			local ModelParametersArray = {}
			
			for _, Model in ipairs(self.ModelArray) do table.insert(ModelParametersArray, Model:getModelParameters()) end
			
			self.ModelParametersMerger:setModelParameters(table.unpack(ModelParametersArray))
			
			local MainModelParameters = self.ModelParametersMerger:generate()
			
			for _, CriticModel in ipairs(self.ModelArray) do CriticModel:setModelParameters(MainModelParameters) end
			
			self.MainModelParameters = MainModelParameters


		until (self.IsDistributedLearningRunning == false)

	end)

	coroutine.resume(trainCoroutine)

	return trainCoroutine
		
end

function DistributedLearning:stop()
	
	self.IsDistributedLearningRunning = false
	
end

function DistributedLearning:reset()
	
	self.currentTotalNumberOfReinforcementsToUpdateMainModel = 0
	
end

function DistributedLearning:destroy()

	setmetatable(self, nil)

	table.clear(self)

	self = nil

end

return DistributedLearning
