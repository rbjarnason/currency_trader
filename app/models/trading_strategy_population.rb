# Setup for evolution
NUMBER_OF_BINARY_EVOLUTION_PARAMETERS = 5
NUMBER_OF_FLOAT_EVOLUTION_PARAMETERS = 18

class StrategyBinaryParameters < BitStringGenotype((TradingStrategySet::MAX_NUMBER_OF_TRADING_STRATEGIES+1)*NUMBER_OF_BINARY_EVOLUTION_PARAMETERS)
  use Elitism(TruncationSelection(0.2),1), UniformCrossover, ListMutator(:probability[ p=0.15],:flip)
end

class StrategyFloatParameters <  FloatListGenotype((TradingStrategySet::MAX_NUMBER_OF_TRADING_STRATEGIES+1)*NUMBER_OF_FLOAT_EVOLUTION_PARAMETERS)
 use Elitism(TruncationSelection(0.5),1), UniformCrossover, ListMutator(:probability[ p=0.4 ],:uniform[ max_size=72 ])
end

genotypes = []
genotypes << [StrategyBinaryParameters,nil]
genotypes << [StrategyFloatParameters,(-500.0..500.0)]

class TradingStrategySetParameters < ComboGenotype(genotypes)
 attr_reader :trading_strategy_set_id
 attr_writer :trading_strategy_set_id

 def fitness=(f)
   @ifitness=f
    Rails.logger.info("set fitness for #{self.object_id} to #{f}")
 end

 def fitness
    Rails.logger.info("get fitness for #{self.object_id} from #{@ifitness}")
   @ifitness
 end

#  use Elitism(TruncationSelection(0.3),1), ComboCrossover, ComboMutator()
 use Elitism(TruncationSelection(0.3),2), ComboCrossover, ComboMutator()
end

class TradingStrategyPopulation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::OptimisticLocking

  field :quote_target_id, type: Integer
  field :complete, type: Boolean, default: false
  field :active, type: Boolean, default: false
  field :in_process, type: Boolean, default: false
  field :best_fitness, type: Float

  field :last_processing_start_time, type: DateTime
  field :last_processing_stop_time, type: DateTime
  field :simulation_end_date, type: DateTime

  field :current_generation, type: Integer, default: 0
  field :max_generations, type: Integer, default: 0
  field :population_size, type: Integer, default: 0
  field :best_trading_strategy_set_id, type: String
  field :current_generation, type: Integer, default: 0
  field :simulation_number_of_trading_strategies_per_set, type: Integer
  field :simulation_days_back, type: Integer, default: 0
  field :simulation_min_overall_trading_signals, type: Integer
  field :simulation_max_daily_trading_signals, type: Integer
  field :simulation_max_minutes_back, type: Integer
  field :simulation_max_overall_trading_signals, type: Integer

  field :population_data, type: Array
  field :description, type: Moped::BSON::Binary

  has_many :trading_strategy_sets do
     def where_not_complete
       where(:complete => true)
     end
   end

  attr_reader :population
  before_save :marshall_population
  after_initialize :demarshall_population

  def quote_target
    QuoteTarget.where(:id=>self.quote_target_id).first
  end

  def quote_target=(quote_target)
    self.quote_target_id = quote_target.id
  end

  def initialize_population
    @population = NetworkedPopulation.new(TradingStrategySetParameters,self.population_size)
    puts @population
    create_trading_strategy_sets(@population)
  end

  def best_set
    if self.best_trading_strategy_set_id
      TradingStrategySet.find(self.best_trading_strategy_set_id)
    else
      nil
    end
  end

  def evolve
      demarshall_population unless @population
      Rails.logger.info("evolve")
      unless @population.complete or self.current_generation>=self.max_generations
        import_population_fitness
        @population = @population.evolve_incremental_block(self.max_generations,Rails.logger)
        create_trading_strategy_sets(@population)
        self.current_generation = @population.generation
        Rails.logger.info("Generation: #{self.current_generation}")
      else
        Rails.logger.info("Reached max generations")
        self.complete=true
      end
      #remove_bottom_strategies
    end

    def is_generation_testing_complete?
      self.trading_strategy_sets.where(:complete => false, :error_flag => 0).size == 0
    end

    def deactivate_all_trading_strategy_sets_in_process
      self.trading_strategy_sets.each do |strategy|
        strategy.in_population_process = false
        strategy.save
      end
    end

    private

    def import_population_fitness
      Rails.logger.info("import_population_fitness")
      for strategy in @population
        trading_strategy_set = TradingStrategySet.find(strategy.trading_strategy_set_id)
        strategy.fitness = trading_strategy_set.fitness
        self.best_fitness = -1000000.0 unless self.best_fitness
        if strategy.fitness > self.best_fitness
          self.best_fitness = strategy.fitness
          self.best_trading_strategy_set_id = trading_strategy_set.id
        end
      end
    end

    def marshall_population
  #    Rails.logger.info(@population.inspect) if @population
      self.population_data = Marshal.dump(@population).unpack("C*").pack("U*") if @population
    end

    def demarshall_population
  #    Rails.logger.debug(self.population_data.inspect)
      @population = Marshal.load(self.population_data.unpack("U*").pack("C*")) if self.population_data

    end

    def remove_bottom_strategies(upto=2)
      if @population.length>upto
        for strategy in @population[@population.length-upto..@population.length-1]
          trading_strategy_set = TradingStrategySet.find(strategy.trading_strategy_set_id)
          trading_strategy_set.destroy
        end
      end
    end

    def create_trading_strategy_sets(settings)
      Rails.logger.info("create_trading_strategy_sets")
      #TODO: Find a better way to do this below as over time there will be too many trading positions
      #used_trading_strategies = []
      #used_trading_strategies += TradingPosition.all.collect { |p| p.trading_strategy_id }
      #used_trading_strategies += TradingSignal.all.collect { |p| p.trading_strategy_id }
      #TradingStrategy.where(["id not in (?)",used_trading_strategies.uniq]).delete_all
      #used_trading_strategies_sets = []
      #used_trading_strategies_sets << self.best_trading_strategy_set_id
      #self.trading_strategy_sets.where(["id not in (?)",used_trading_strategies_sets.uniq]).delete_all
      for setting in settings
        trading_strategy_set = TradingStrategySet.new
        trading_strategy_set.trading_strategy_population = self
        trading_strategy_set.trading_time_frame_id = TradingTimeFrame.last.id
        trading_strategy_set.save
        trading_strategy_set.setup_trading_strategies
        trading_strategy_set.import_settings_from_population(self,setting)
        trading_strategy_set.active = true
        trading_strategy_set.in_population_process = true
        trading_strategy_set.save
        setting.trading_strategy_set_id = trading_strategy_set.id
        Rails.logger.info("create_trading_strategy_sets id: #{trading_strategy_set.id}")
      end
      Rails.logger.info("After transaction")
    end
  end
