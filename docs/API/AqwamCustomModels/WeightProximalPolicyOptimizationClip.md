# [API Reference](../../API.md) - [AqwamCustomModels](../AqwamCustomModels.md) - WeightProximalPolicyOptimizationClip (WPPO-Clip)

WeightProximalPolicyOptimizationClip is a base class for reinforcement learning.

It is a modified ProximalPolicyOptimizationClip where the ratio of the weights are used instead of the action probability vector. Hopefully, by directly optimizing the weights, it makes things more sample efficient due to no backpropagation required.

## Notes

* The Actor and Critic models must be created separately. Then use setActorModel() and setCriticModel() to put it inside the AdvantageActorCritic model.

* Actor and Critic models must be a part of NeuralNetwork model. If you decide to use linear regression or logistic regression, then it must be constructed using NeuralNetwork model. 

* Ensure the final layer of the Critic model has only one neuron. It is the default setting for all Critic models in research papers.

## Constructors

### new()

Create new model object. If any of the arguments are nil, default argument values for that argument will be used.

```
WeightProximalPolicyOptimizationClip.new(clipRatio: number, discountFactor: number): ModelObject
```

#### Parameters:

* clipRatio: A value that controls how far the new policy can get far from old policy. The value must be set between 0 and 1.

* discountFactor: The higher the value, the more likely it focuses on long-term outcomes. The value must be set between 0 and 1.

#### Returns:

* ModelObject: The generated model object.

## Functions

### setParameters()

Set model's parameters. When any of the arguments are nil, previous argument values for that argument will be used.

```
WeightProximalPolicyOptimizationClip:setParameters(clipRatio: number, discountFactor: number)
```

#### Parameters:

* clipRatio: A value that controls how far the new policy can get far from old policy. The value must be set between 0 and 1.

* discountFactor: The higher the value, the more likely it focuses on long-term outcomes. The value must be set between 0 and 1.

## Inherited From

* [ReinforcementLearningActorCriticBaseModel](ReinforcementLearningActorCriticBaseModel.md)

## References

* [Proximal Policy Optimization By OpenAI](https://spinningup.openai.com/en/latest/algorithms/ppo.html)