class TradingStrategySet < ActiveRecord::Base
  MAX_NUMBER_OF_TRADING_STRATEGIES = 1

  has_many :trading_strategies, :dependent => :destroy
  belongs_to :trading_strategy_population
  belongs_to :trading_time_frame

  def calculate_fitness
    self.accumulated_fitness = 0.0
    trading_strategies.each do |strategy|
      Rails.logger.debug("Get fitness for strategy #{strategy.id}")
      self.accumulated_fitness+=strategy.fitness(QuoteTarget.last, (Date.today - 4),Date.today,4,2000000)
      Rails.logger.debug(self.accumulated_fitness)
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
    (1..MAX_NUMBER_OF_TRADING_STRATEGIES).each do |nr|
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
        split_attributes = genotype.genes.each_slice(10).to_a
        Rails.logger.debug("SPLIT binary parameters #{split_attributes}")
        import_binary_parameters(split_attributes[0])
        (0..MAX_NUMBER_OF_TRADING_STRATEGIES-1).each do |i|
          all_trading_strategies[i].import_binary_parameters(split_attributes[i+1])
        end
      elsif genotype.instance_of?(StrategyFloatParameters)
        split_attributes = genotype.genes.each_slice(40).to_a
        Rails.logger.debug("SPLIT float parameters #{split_attributes}")
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
