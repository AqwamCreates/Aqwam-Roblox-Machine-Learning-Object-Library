local BaseModel = require(script.Parent.BaseModel)

LinearRegressionModel = {}

LinearRegressionModel.__index = LinearRegressionModel

setmetatable(LinearRegressionModel, BaseModel)

local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamRobloxMatrixLibraryLinker.Value)

local defaultMaxNumberOfIterations = 500

local defaultLearningRate = 0.3

local defaultLossFunction = "L2"

local defaultTargetCost = 0

local lossFunctionList = {

	["L1"] = function (x1, x2)

		local part1 = AqwamMatrixLibrary:subtract(x1, x2)
		
		part1 = AqwamMatrixLibrary:applyFunction(math.abs, part1)

		local distance = AqwamMatrixLibrary:sum(part1)

		return distance 

	end,

	["L2"] = function (x1, x2)

		local part1 = AqwamMatrixLibrary:subtract(x1, x2)

		local part2 = AqwamMatrixLibrary:power(part1, 2)

		local distance = AqwamMatrixLibrary:sum(part2)

		return distance 

	end,

}
local function calculateHypothesisVector(featureMatrix, modelParameters)
	
	return AqwamMatrixLibrary:dotProduct(featureMatrix, modelParameters)
	
end

local function calculateCost(modelParameters, featureMatrix, labelVector, lossFunction)
	
	local numberOfData = #featureMatrix
	
	local hypothesisVector = calculateHypothesisVector(featureMatrix, modelParameters)
	
	if (type(hypothesisVector) == "number") then hypothesisVector = {{hypothesisVector}} end
	
	local costVector = lossFunctionList[lossFunction](hypothesisVector, labelVector) 
	
	local averageCost = costVector / (2 * numberOfData)
	
	return averageCost
	
end

local function gradientDescent(modelParameters, featureMatrix, labelVector, lossFunction)
	
	local numberOfData = #featureMatrix
	
	local hypothesisVector = calculateHypothesisVector(featureMatrix, modelParameters)
	
	local calculatedError = AqwamMatrixLibrary:subtract(hypothesisVector, labelVector)

	local calculatedErrorWithFeatureMatrix = AqwamMatrixLibrary:dotProduct(AqwamMatrixLibrary:transpose(featureMatrix), calculatedError)

	local costFunctionDerivative = AqwamMatrixLibrary:multiply((1/numberOfData),  calculatedErrorWithFeatureMatrix)
	
	return costFunctionDerivative
	
end

function LinearRegressionModel.new(maxNumberOfIterations, learningRate, lossFunction, targetCost)
	
	local NewLinearRegressionModel = BaseModel.new()
	
	setmetatable(NewLinearRegressionModel, LinearRegressionModel)
	
	NewLinearRegressionModel.maxNumberOfIterations = maxNumberOfIterations or defaultMaxNumberOfIterations
	
	NewLinearRegressionModel.learningRate = learningRate or defaultLearningRate
	
	NewLinearRegressionModel.lossFunction = lossFunction or defaultLossFunction
	
	NewLinearRegressionModel.targetCost = targetCost or defaultTargetCost
	
	NewLinearRegressionModel.validationFeatureMatrix = nil
	
	NewLinearRegressionModel.validationLabelVector = nil
	
	NewLinearRegressionModel.Optimizer = nil
	
	NewLinearRegressionModel.Regularization = nil
	
	return NewLinearRegressionModel
	
end

function LinearRegressionModel:setParameters(maxNumberOfIterations, learningRate, lossFunction, targetCost)

	self.maxNumberOfIterations = maxNumberOfIterations or self.maxNumberOfIterations

	self.learningRate = learningRate or self.learningRate

	self.lossFunction = lossFunction or self.lossFunction

	self.targetCost = targetCost or self.targetCost
	
end

function LinearRegressionModel:setOptimizer(Optimizer)
	
	self.Optimizer = Optimizer
	
end

function LinearRegressionModel:setRegularization(Regularization)
	
	self.Regularization = Regularization
	
end

function LinearRegressionModel:train(featureMatrix, labelVector)

	local cost

	local costArray = {}
	
	local numberOfIterations = 0
	
	local costFunctionDerivatives
	
	local numberOfData = #featureMatrix[1]
	
	local previousCostFunctionDerivatives
	
	local RegularizationDerivatives
	
	local regularizationCost
	
	if (#featureMatrix ~= #labelVector) then error("The feature matrix and the label vector does not contain the same number of rows!") end
	
	if (self.ModelParameters) then
		
		if (#featureMatrix[1] ~= #self.ModelParameters) then error("The number of features are not the same as the model parameters!") end
		
	else
		
		self.ModelParameters = self:initializeMatrixBasedOnMode(#featureMatrix[1], 1)
		
	end
	
	repeat
		
		self:iterationWait()
		
		numberOfIterations += 1
		
		costFunctionDerivatives = gradientDescent(self.ModelParameters, featureMatrix, labelVector, self.lossFunction)
		
		costFunctionDerivatives = AqwamMatrixLibrary:multiply(self.learningRate, costFunctionDerivatives)
		
		if (self.Optimizer) then 

			costFunctionDerivatives = self.Optimizer:calculate(costFunctionDerivatives, previousCostFunctionDerivatives) 

		end
		
		if (self.Regularization) then
			
			RegularizationDerivatives = self.Regularization:calculateCostFunctionDerivativeRegularization(self.ModelParameters, numberOfData)
			
			costFunctionDerivatives = AqwamMatrixLibrary:add(costFunctionDerivatives, RegularizationDerivatives)

		end
		
		previousCostFunctionDerivatives = costFunctionDerivatives
		
		self.ModelParameters = AqwamMatrixLibrary:subtract(self.ModelParameters, costFunctionDerivatives)
		
		cost = calculateCost(self.ModelParameters, featureMatrix, labelVector, self.lossFunction)
		
		if (self.Regularization) then 

			regularizationCost = self.Regularization:calculateCostFunctionRegularization(self.ModelParameters, numberOfData)
			
			cost += regularizationCost

		end
		
		table.insert(costArray, cost)
		
		self:printCostAndNumberOfIterations(cost, numberOfIterations)
		
	until (numberOfIterations == self.maxNumberOfIterations) or (math.abs(cost) <= self.targetCost)
	
	if (cost == math.huge) then warn("The model diverged! Please repeat the experiment again or change the argument values") end
	
	if self.Optimizer then self.Optimizer:reset() end
	
	return costArray
	
end

function LinearRegressionModel:predict(featureMatrix)
	
	return AqwamMatrixLibrary:dotProduct(featureMatrix, self.ModelParameters)

end

return LinearRegressionModel
