class TradingStrategySet < ActiveRecord::Base
  MAX_NUMBER_OF_TRADING_STRATEGIES = 5

  has_many :trading_strategies, :dependent => :destroy
  belongs_to :trading_strategy_population
  belongs_to :trading_time_frame

  def fitness
    accumulated_fitness = 0.0
    trading_strategies.each do |strategy|
      accumulated_fitness+=strategy.fitness(QuoteTarget.last, (Date.today - 7),Date.today,1,2000000)
    end
    accumulated_fitness
  end

  def import_binary_parameters(binary_parameters)
  end

  def import_float_parameters(float_parameters)
  end

  def import_settings_from_population(population,setting)
    all_trading_strategies = trading_strategies.all
    setting.get_genotypes.each do |genotype|
      if genotype.instance_of?(StrategyBinaryParameters)
        split_attributes = genotype.genes.slice(MAX_NUMBER_OF_TRADING_STRATEGIES+1)
        set_binary_parameters(split_attributes[0])
        (0..MAX_NUMBER_OF_TRADING_STRATEGIES-1).each do |i|
          all_trading_strategies[i].import_binary_parameters(split_attributes[i+1])
        end
      elsif genotype.instance_of?(StrategyFloatParameters)
        split_attributes = genotype.genes.slice(MAX_NUMBER_OF_TRADING_STRATEGIES+1)
        import_float_parameters(split_attributes[0])
        (0..MAX_NUMBER_OF_TRADING_STRATEGIES-1).each do |i|
          all_trading_strategies[i].import_float_parameters(split_attributes[i+1])
        end
      end
    end
    all_trading_strategies.each do |strategy|
      strategy.save
    end
    #Rails.logger.info("Id: #{self.id} Max Epochs: #{self.max_epochs} Desired error: #{self.desired_error} Hidden Neurons: #{@hidden_neurons.inspect} Selected inputs: #{@selected_inputs.inspect} Input scaling: #{@inputs_scaling.inspect}")
  end
end
