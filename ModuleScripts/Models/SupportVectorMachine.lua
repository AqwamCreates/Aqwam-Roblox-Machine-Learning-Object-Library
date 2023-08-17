local DataPredictLibrary = script.Parent.Parent

local SupportVectorMachine = require(DataPredictLibrary.Models.SupportVectorMachine)

local Optimizers = DataPredictLibrary.Optimizers

local AqwamMatrixLibrary = require(script.Parent.Parent.AqwamRobloxMatrixLibraryLinker.Value)

local defaultMaxNumberOfIterations = 500

local defaultLearningRate = 0.3

local defaultCvalue = 0.0

local defaultTargetCost = 0

local defaultKernelFunction = "linear"

local SupportVectorMachineOneVsAllModel = {}

SupportVectorMachineOneVsAllModel.__index = SupportVectorMachineOneVsAllModel

local function getClassesList(labelVector)

	local classesList = {}

	local value

	for i = 1, #labelVector, 1 do

		value = labelVector[i][1]

		if not table.find(classesList, value) then

			table.insert(classesList, value)

		end

	end

	return classesList

end

local function convertToBinaryLabelVector(labelVector, selectedClass)

	local numberOfRows = #labelVector

	local newLabelVector = AqwamMatrixLibrary:createMatrix(numberOfRows, 1)

	for row = 1, numberOfRows, 1 do

		if (labelVector[row][1] == selectedClass) then

			newLabelVector[row][1] = 1

		else

			newLabelVector[row][1] = -1

		end

	end

	return newLabelVector

end

function SupportVectorMachineOneVsAllModel.new(maxNumberOfIterations, learningRate, cValue, targetCost, kernelFunction, kernelParameters)

	local NewSupportVectorMachineOneVsAll = {}

	setmetatable(NewSupportVectorMachineOneVsAll, SupportVectorMachineOneVsAllModel)

	NewSupportVectorMachineOneVsAll.maxNumberOfIterations = maxNumberOfIterations or defaultMaxNumberOfIterations

	NewSupportVectorMachineOneVsAll.learningRate = learningRate or defaultLearningRate

	NewSupportVectorMachineOneVsAll.cValue = cValue or defaultCvalue

	NewSupportVectorMachineOneVsAll.targetCost = targetCost or defaultTargetCost

	NewSupportVectorMachineOneVsAll.kernelFunction = kernelFunction or defaultKernelFunction

	NewSupportVectorMachineOneVsAll.kernelParameters = kernelParameters or {}

	NewSupportVectorMachineOneVsAll.validationFeatureMatrix = nil

	NewSupportVectorMachineOneVsAll.validationLabelVector = nil

	NewSupportVectorMachineOneVsAll.Optimizer = nil

	NewSupportVectorMachineOneVsAll.IsOutputPrinted = false

	return NewSupportVectorMachineOneVsAll

end

function SupportVectorMachineOneVsAllModel:setParameters(maxNumberOfIterations, learningRate, cValue, targetCost, kernelFunction, kernelParameters)

	self.maxNumberOfIterations = maxNumberOfIterations or self.maxNumberOfIterations

	self.learningRate = learningRate or self.learningRate

	self.cValue = cValue or self.cValue

	self.targetCost = targetCost or self.targetCost

	self.kernelFunction = kernelFunction or self.kernelFunction

	self.kernelParameters = kernelParameters or self.kernelParameters

end

function SupportVectorMachineOneVsAllModel:train(featureMatrix, labelVector)

	local classesList = getClassesList(labelVector)

	table.sort(classesList, function(a,b) return a < b end)

	local total

	local totalCost

	local cost

	local costArray = {}
	
	local internalCostArray = {}

	local ModelParameters = {}

	local SupportVectorMachineModel

	local SupportVectorMachineModelsArray = {}

	local binaryLabelVector

	local binaryLabelVectorTable = {}

	local ModelParametersVectorColumn

	local ModelParametersVectorRow

	local numberOfIterations = 0

	self.ClassesList = classesList

	for i, class in ipairs(classesList) do

		SupportVectorMachineModel = SupportVectorMachine.new(1, self.learningRate, self.cValue, self.targetCost, self.kernelFunction, self.kernelParameters)

		SupportVectorMachineModel:setPrintOutput(false) 

		binaryLabelVector = convertToBinaryLabelVector(labelVector, class)

		table.insert(SupportVectorMachineModelsArray, SupportVectorMachineModel)

		table.insert(binaryLabelVectorTable, binaryLabelVector)

	end

	repeat

		numberOfIterations += 1

		totalCost = 0

		for i, class in ipairs(classesList) do

			binaryLabelVector = binaryLabelVectorTable[i]

			SupportVectorMachineModel = SupportVectorMachineModelsArray[i]

			internalCostArray = SupportVectorMachineModel:train(featureMatrix, binaryLabelVector)

			cost = internalCostArray[1]

			totalCost += cost

		end

		if self.IsOutputPrinted then print("Iteration: " .. numberOfIterations .. "\t\tCost: " .. cost) end

		table.insert(costArray, totalCost)

	until (numberOfIterations == self.maxNumberOfIterations) or (math.abs(totalCost) <= self.targetCost)

	if (cost == math.huge) then warn("The model diverged! Please repeat the experiment again or change the argument values.") end

	for i, class in ipairs(classesList) do

		SupportVectorMachineModel = SupportVectorMachineModelsArray[i]

		ModelParametersVectorColumn = SupportVectorMachineModel:getModelParameters()

		ModelParametersVectorRow = AqwamMatrixLibrary:transpose(ModelParametersVectorColumn)

		table.insert(ModelParameters, ModelParametersVectorRow[1])

	end

	self.ModelParameters = AqwamMatrixLibrary:transpose(ModelParameters)

	return costArray

end

function SupportVectorMachineOneVsAllModel:predict(featureMatrix, returnOriginalOutput)

	local distanceMatrix = AqwamMatrixLibrary:dotProduct(featureMatrix, self.ModelParameters)
	
	if (returnOriginalOutput == true) then return distanceMatrix end
	
	local predictedLabelVector = AqwamMatrixLibrary:createMatrix(#featureMatrix, 1)

	local highestDistanceVector = AqwamMatrixLibrary:createMatrix(#featureMatrix, 1)

	for j = 1, #distanceMatrix, 1 do

		local distance = {distanceMatrix[j]}

		local highestProbability, classIndex = AqwamMatrixLibrary:findMaximumValueInMatrix(distance)

		if (classIndex == nil) then continue end

		local predictedLabel = self.ClassesList[classIndex[2]]

		predictedLabelVector[j][1] = predictedLabel

		highestDistanceVector[j][1] = highestProbability

	end

	return predictedLabelVector, highestDistanceVector

end

function SupportVectorMachineOneVsAllModel:getModelParameters()

	return self.ModelParameters

end

function SupportVectorMachineOneVsAllModel:getClassesList()

	return self.ClassesList

end

function SupportVectorMachineOneVsAllModel:setModelParameters(ModelParameters)

	self.ModelParameters = ModelParameters

end

function SupportVectorMachineOneVsAllModel:setClassesList(ClassesList)

	self.ClassesList = ClassesList

end

function SupportVectorMachineOneVsAllModel:setPrintOutput(option) 

	if (option == false) then

		self.IsOutputPrinted = false

	else

		self.IsOutputPrinted = true

	end

end

return SupportVectorMachineOneVsAllModel
