class TradingStrategySet
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::OptimisticLocking

  MAX_NUMBER_OF_TRADING_STRATEGIES = 10
  FORCE_RELEASE_POSITION = true
  PUNISHMENT_FOR_SAME_MINUTES_IN_STRATEGIES = 0.7

  has_many :trading_strategies
  belongs_to :trading_strategy_population
  belongs_to :trading_time_frame
  #has_one :trading_time_frame

  field :parameters, type: Moped::BSON::Binary

  field :processing_time_interval, type: Integer

  field :fitness_score, type: Float
  field :accumulated_fitness, type: Float

  field :complete, type: Boolean, default: false
  field :error_flag, type: Boolean, default: false
  field :active, type: Boolean, default: false
  field :in_population_process, type: Boolean, default: false
  field :in_process, type: Boolean, default: false

  field :last_processing_start_time, type: DateTime
  field :last_processing_stop_time, type: DateTime
  field :last_work_unit_time, type: DateTime

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
      Rails.logger.debug("Get fitness for strategy #{strategy.id}")
      strategy_fitness = strategy.fitness
      how_far_back_minutes_open << (strategy.open_how_far_back_milliseconds/1000/60).to_i
      how_far_back_minutes_close << (strategy.close_how_far_back_milliseconds/1000/60).to_i
      self.accumulated_fitness+=strategy_fitness if strategy_fitness>0.0
      Rails.logger.debug(self.accumulated_fitness)
    end
    if how_far_back_minutes_open.uniq.length!=trading_strategies.count
      self.accumulated_fitness=self.accumulated_fitness*PUNISHMENT_FOR_SAME_MINUTES_IN_STRATEGIES
      Rails.logger.info("#{how_far_back_minutes_open} To Similar Open Minutes Punish")
    end
    if how_far_back_minutes_close.uniq.length!=trading_strategies.count
      self.accumulated_fitness=self.accumulated_fitness*PUNISHMENT_FOR_SAME_MINUTES_IN_STRATEGIES
      Rails.logger.info("#{how_far_back_minutes_close} To Similar Close Minutes Punish")
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
#    population.simulation_number_of_trading_strategies_per_set.times do
    3.times do
      strategy=TradingStrategy.new
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
