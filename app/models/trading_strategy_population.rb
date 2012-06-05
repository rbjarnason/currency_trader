# Setup for evolution
NUMBER_OF_BINARY_EVOLUTION_PARAMETERS = 5
NUMBER_OF_FLOAT_EVOLUTION_PARAMETERS = 5

class StrategyBinaryParameters < BitStringGenotype((TradingStrategySet::MAX_NUMBER_OF_TRADING_STRATEGIES+1)*NUMBER_OF_BINARY_EVOLUTION_PARAMETERS)
  use Elitism(TruncationSelection(0.2),1), UniformCrossover, ListMutator(:probability[ p=0.15],:flip)
end

class StrategyFloatParameters <  FloatListGenotype((TradingStrategySet::MAX_NUMBER_OF_TRADING_STRATEGIES+1)*NUMBER_OF_FLOAT_EVOLUTION_PARAMETERS)
 use Elitism(TruncationSelection(0.5),1), UniformCrossover, ListMutator(:probability[ p=0.4 ],:uniform[ max_size=25 ])
end

genotypes = []
genotypes << [StrategyBinaryParameters,nil]
genotypes << [StrategyFloatParameters,(-50.0..50.0)]

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

class TradingStrategyPopulation < ActiveRecord::Base
  has_many :trading_strategy_sets, :dependent => :destroy do
     def count_not_complete
       count :all, :conditions=>["complete = ?",0]
     end
   end

  belongs_to :quote_target
  attr_reader :population
  before_save :marshall_population
  after_initialize :demarshall_population

  def initialize_population
    @population = NetworkedPopulation.new(TradingStrategySetParameters,self.population_size)
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
      self.trading_strategy_sets.where("complete = 0 AND error_flag = 0").count == 0
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
      self.population_data = Marshal.dump(@population) if @population
    end

    def demarshall_population
  #    Rails.logger.debug(self.population_data.inspect)
      @population = Marshal.load(self.population_data) if self.population_data

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
      TradingStrategySet.transaction do
        #TODO: Find a better way to do this below as over time there will be too many trading positions
        used_trading_strategies = []
        used_trading_strategies << self.best_trading_strategy_set_id
        used_trading_strategies += TradingPosition.all.collect { |p| p.trading_strategy_id }
        self.trading_strategy_sets.where(["id not in (?)",used_trading_strategies]).destroy_all
        for setting in settings
          trading_strategy_set = TradingStrategySet.new
          trading_strategy_set.trading_strategy_population_id = self.id
          trading_strategy_set.trading_time_frame = TradingTimeFrame.last
          trading_strategy_set.save
          trading_strategy_set.setup_trading_strategies
          trading_strategy_set.import_settings_from_population(self,setting)
          trading_strategy_set.active = true
          trading_strategy_set.in_population_process = true
          trading_strategy_set.save
          setting.trading_strategy_set_id = trading_strategy_set.id
          Rails.logger.info("create_trading_strategy_sets id: #{trading_strategy_set.id}")
        end
      end
    end
  end
