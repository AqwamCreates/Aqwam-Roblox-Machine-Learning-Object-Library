local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamMatrixLibraryLinker.Value)

local ModelChecker = {}

ModelChecker.__index = ModelChecker

local defaultMaxNumberOfIterations = 100

local defaultMaxGeneralizationError = math.huge

local logLossFunction = function (y, p) return -(y * math.log(p)) end

function ModelChecker.new(Model, modelType, maxNumberOfIterations, maxGeneralizationError)
	
	if (Model == nil) then error("No model in the ModelChecker!") end

	if (modelType == nil) then error("No model type in the ModelChecker!") end
	
	local NewModelChecker = {}
	
	setmetatable(NewModelChecker, ModelChecker)
	
	NewModelChecker.Model = Model
	
	NewModelChecker.modelType = modelType
	
	NewModelChecker.maxNumberOfIterations = maxNumberOfIterations or defaultMaxNumberOfIterations
	
	NewModelChecker.maxGeneralizationError = maxGeneralizationError or defaultMaxGeneralizationError
	
	return NewModelChecker
	
end

function ModelChecker:setParameters(Model, modelType, maxNumberOfIterations, maxGeneralizationError)
	
	self.Model = Model or self.Model
	
	self.modelType = modelType or self.modelType

	self.maxNumberOfIterations = maxNumberOfIterations or self.maxNumberOfIterations
	
	self.maxGeneralizationError = maxGeneralizationError or self.maxGeneralizationError
	
end

function ModelChecker:setClassesList(classesList)

	self.ClassesList = classesList

end

function ModelChecker:convertLabelVectorToLogisticMatrix(labelVector)

	if (typeof(labelVector) == "number") then

		labelVector = {{labelVector}}

	end

	local logisticMatrix = AqwamMatrixLibrary:createMatrix(#labelVector, #self.ClassesList)

	local label

	local labelPosition

	for row = 1, #labelVector, 1 do

		label = labelVector[row][1]

		labelPosition = table.find(self.ClassesList, label)

		logisticMatrix[row][labelPosition] = 1

	end

	return logisticMatrix

end

function ModelChecker:testClassification(testFeatureMatrix, testLabelVector)
	
	local testLogisticMatrix
	
	if (#testLabelVector[1] == 1) then

		testLogisticMatrix = self:convertLabelVectorToLogisticMatrix(testLabelVector)

	else

		testLogisticMatrix = testLabelVector

	end
	
	local numberOfData = #testFeatureMatrix
	
	local predictedLabelMatrix = self.Model:predict(testFeatureMatrix, true)
	
	local errorMatrix = AqwamMatrixLibrary:applyFunction(logLossFunction, testLogisticMatrix, predictedLabelMatrix)
	
	local errorVector = AqwamMatrixLibrary:horizontalSum(errorMatrix)
	
	local totalError = AqwamMatrixLibrary:sum(errorVector)
	
	local testCost = totalError / numberOfData

	return testCost, errorVector, predictedLabelMatrix

end

function ModelChecker:testRegression(testFeatureMatrix, testLabelVector)

	local numberOfData = #testFeatureMatrix
	
	local predictedLabelVector = self.Model:predict(testFeatureMatrix)

	local errorVector = AqwamMatrixLibrary:subtract(predictedLabelVector, testLabelVector)

	local totalError = AqwamMatrixLibrary:sum(errorVector)

	local testCost = totalError/numberOfData

	return testCost, errorVector, predictedLabelVector

end

function ModelChecker:validateClassification(trainFeatureMatrix, trainLabelVector, validationFeatureMatrix, validationLabelVector)

	local trainCost

	local validationCost
	
	local validationCostVector
	
	local predictedLabelMatrix
	
	local validationLogisticMatrix
	
	local generalizationError
	
	local numberOfIterations = 0

	local trainCostArray = {}

	local validationCostArray = {}
	
	local numberOfValidationData = #validationFeatureMatrix 
	
	if (#validationLabelVector[1] == 1) then
		
		validationLogisticMatrix = self:convertLabelVectorToLogisticMatrix(validationLabelVector)
		
	else
		
		validationLogisticMatrix = validationLabelVector
		
	end

	repeat

		trainCost = self.Model:train(trainFeatureMatrix, trainLabelVector)
		
		predictedLabelMatrix = self.Model:predict(validationFeatureMatrix, true)
	
		validationCostVector = AqwamMatrixLibrary:applyFunction(logLossFunction, validationLogisticMatrix, predictedLabelMatrix)
		
		validationCost = AqwamMatrixLibrary:sum(validationCostVector)
		
		validationCost /= numberOfValidationData
		
		generalizationError = validationCost - trainCost[1]

		table.insert(validationCostArray, validationCost)

		table.insert(trainCostArray, trainCost[1])

		numberOfIterations += 1

	until (numberOfIterations >= self.maxNumberOfIterations) or (generalizationError >= self.maxGeneralizationError)

	return trainCostArray, validationCostArray

end

function ModelChecker:validateRegression(trainFeatureMatrix, trainLabelVector, validationFeatureMatrix, validationLabelVector)
	
	local trainCost
	
	local validationCost
	
	local validationCostVector
	
	local predictedLabelVector
	
	local generalizationError
	
	local numberOfIterations = 0

	local trainCostArray = {}

	local validationCostArray = {}
	
	local numberOfValidationData = #validationFeatureMatrix
	
	repeat
		
		trainCost = self.Model:train(trainFeatureMatrix, trainLabelVector)
		
		predictedLabelVector = self.Model:predict(validationFeatureMatrix)
		
		validationCostVector = AqwamMatrixLibrary:subtract(predictedLabelVector, validationLabelVector)
		
		validationCost = AqwamMatrixLibrary:sum(validationCostVector)
		
		validationCost /= numberOfValidationData
		
		generalizationError = validationCost - trainCost[1]
		
		table.insert(validationCostArray, validationCost)
		
		table.insert(trainCostArray, trainCost[1])
		
		numberOfIterations += 1
		
	until (numberOfIterations >= self.maxNumberOfIterations) or (generalizationError >= self.maxGeneralizationError)
	
	return trainCostArray, validationCostArray
	
end

function ModelChecker:test(testFeatureMatrix, testLabelVector)
	
	local testCost

	local errorVector
	
	local predictedLabelMatrix

	if (self.modelType == "Regression") then

		testCost, errorVector, predictedLabelMatrix = self:testRegression(testFeatureMatrix, testLabelVector)

	elseif (self.modelType == "Classification") then

		testCost, errorVector, predictedLabelMatrix = self:testClassification(testFeatureMatrix, testLabelVector)
		
	else
		
		error("Invalid model type!")

	end

	return testCost, errorVector, predictedLabelMatrix

end

function ModelChecker:validate(trainFeatureMatrix, trainLabelVector, validationFeatureMatrix, validationLabelVector)
	
	local trainCostArray
	
	local validationCostArray
	
	if (self.modelType == "Regression") then
		
		trainCostArray, validationCostArray = self:validateRegression(trainFeatureMatrix, trainLabelVector, validationFeatureMatrix, validationLabelVector)
		
	elseif (self.modelType == "Classification") then
		
		trainCostArray, validationCostArray = self:validateClassification(trainFeatureMatrix, trainLabelVector, validationFeatureMatrix, validationLabelVector)
		
	else
		
		error("Invalid model type!")
		
	end
	
	return trainCostArray, validationCostArray
	
end

return ModelChecker
