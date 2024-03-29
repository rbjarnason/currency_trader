class TradingStrategySet < ActiveRecord::Base
  MAX_NUMBER_OF_TRADING_STRATEGIES = 3
  FORCE_RELEASE_POSITION = false
  PENALTY_FOR_SAME_MINUTES_IN_STRATEGIES = 0.7
  USE_SELF_SIMILARITY_PENALTY = false
  
  has_many :trading_strategies, :dependent => :destroy
  belongs_to :trading_strategy_population
  belongs_to :trading_time_frame

  def no_delete!
    #self.no_delete = true
    #self.save
    #self.trading_strategies.each do |strategy|
    #  strategy.no_delete!
    #end
  end

  def population
    self.trading_strategy_population
  end

  def calculate_fitness
    # MISSING SECOND LAYER OF TEST WHERE THE BEST EVOLVED CATEGORIES ARE FITNESS TESTED FOR RANDOM SAMPLE (OUT OF TRAINING DATA) RATE IN SAME CATEGORY
    # ALSO ADD A BONUS THE MORE UNIFORM THE PROFIT IT OVER THE DAYS, AS IN NOT MAKING ALL THE PROFITS IN SPECIAL CIRCOMSTANCES
    self.accumulated_fitness = 0.0
    how_far_back_minutes_open = []
    how_far_back_minutes_close = []

    trading_strategies.each do |strategy|
      Rails.logger.info("Get fitness for strategy #{strategy.id}")
      strategy_fitness = strategy.fitness
      Rails.logger.info("Fitness for strategy #{strategy.id} ready")
      how_far_back_minutes_open << (strategy.open_how_far_back_milliseconds/1000/60).to_i
      how_far_back_minutes_close << (strategy.close_how_far_back_milliseconds/1000/60).to_i
      self.accumulated_fitness+=strategy_fitness if strategy_fitness>0.0
      Rails.logger.debug(self.accumulated_fitness)
    end

    if USE_SELF_SIMILARITY_PENALTY
      if how_far_back_minutes_open.uniq.length!=trading_strategies.count
        self.accumulated_fitness=self.accumulated_fitness*PENALTY_FOR_SAME_MINUTES_IN_STRATEGIES
        Rails.logger.info("#{how_far_back_minutes_open} To Similar Open Minutes Punish")
      end
      if how_far_back_minutes_close.uniq.length!=trading_strategies.count
        self.accumulated_fitness=self.accumulated_fitness*PENALTY_FOR_SAME_MINUTES_IN_STRATEGIES
        Rails.logger.info("#{how_far_back_minutes_close} To Similar Close Minutes Punish")
      end
    end
    self.accumulated_fitness
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
      strategy.trading_strategy_population=self.trading_strategy_population
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
