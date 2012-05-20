class TradingStrategySet < ActiveRecord::Base
  MAX_NUMBER_OF_TRADING_STRATEGIES = 10

  FORCE_RELEASE_POSITION = true

  has_many :trading_strategies, :dependent => :destroy
  belongs_to :trading_strategy_population
  belongs_to :trading_time_frame

  def population
    self.trading_strategy_population
  end

  def calculate_fitness
    self.accumulated_fitness = 0.0
    how_far_back_minutes = []
    trading_strategies.each do |strategy|
      Rails.logger.debug("Get fitness for strategy #{strategy.id}")
      strategy_fitness = strategy.fitness
      how_far_back_minutes << strategy.how_far_back_milliseconds/1000/60
      self.accumulated_fitness+=strategy_fitness if strategy_fitness>0.0
      Rails.logger.debug(self.accumulated_fitness)
    end
    Rails.logger.info("YYYYYYYYYYYY #{how_far_back_minutes}")
    if how_far_back_minutes.uniq.length==trading_strategies.count
      self.accumulated_fitness
    else
      if population.best_trading_strategy_set_id
        if next_best_fitness = TradingStrategySet.find(population.best_trading_strategy_set_id).self.accumulated_fitness
          next_best_fitness*0.9
        else
          0.0
        end
      else
        0.0
      end
    end
  end

  def fitness
    self.accumulated_fitness
  end

  def import_binary_parameters(binary_parameters)
  end

  def import_float_parameters(float_parameters)
  end

  def setup_trading_strategies
    (1..population.simulation_number_of_trading_strategies_per_set.to_i).each do |nr|
      strategy=TradingStrategy.new
      strategy.trading_strategy_template=TradingStrategyTemplate.last
      strategy.trading_strategy_set=self
      strategy.save
    end
  end

  def import_settings_from_population(population,setting)
    setup_trading_strategies if trading_strategies.empty?
    all_trading_strategies = trading_strategies.all
    setting.get_genotypes.each do |genotype|
      if genotype.instance_of?(StrategyBinaryParameters)
        split_attributes = genotype.genes.each_slice(NUMBER_OF_BINARY_EVOLUTION_PARAMETERS).to_a
        Rails.logger.debug("SPLIT binary parameters #{split_attributes}")
        import_binary_parameters(split_attributes[0])
        (0..(population.simulation_number_of_trading_strategies_per_set.to_i)-1).each do |i|
          all_trading_strategies[i].import_binary_parameters(split_attributes[i+1])
        end
      elsif genotype.instance_of?(StrategyFloatParameters)
        split_attributes = genotype.genes.each_slice(NUMBER_OF_FLOAT_EVOLUTION_PARAMETERS).to_a
        Rails.logger.debug("SPLIT float parameters #{split_attributes}")
        import_float_parameters(split_attributes[0])
        (0..(population.simulation_number_of_trading_strategies_per_set.to_i-1)).each do |i|
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
