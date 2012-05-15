class TradingStrategySet < ActiveRecord::Base
  has_many :trading_strategies, :dependent => :destroy
  belongs_to :trading_strategy_population

  def fitness
    # Find how many days back parameter
    # How many trading strategies?
    # For each Trading Strategy
      # Set initial capital
      # Run the simulation minute by minute from the starting point
        # For each minute
          # Is there a buy/short trading signal generated
        # At the end calculate total gain/loss

    for prediction in self.predictions
      from_date=prediction.data_time+@timespan
#      RAILS_DEFAULT_LOGGER.info("From data #{from_date}")
      quote=get_cached_quote_value(from_date)
#      RAILS_DEFAULT_LOGGER.info("#{quote.inspect}") if quote
      if quote
        prediction_distances << (((quote.last_trade.to_f/(prediction.double_value*get_fann_scaling))-1)*100)
      end
    end
    #RAILS_DEFAULT_LOGGER.info("FAverage: NeuralStrategy id: #{self.id} PREDICTION DISTANCES: #{prediction_distances.inspect} self: #{self.predictions} qta: #{self.quote_target_id} timespan: #{@timespan}")
    if prediction_distances.length>2
      average=0.0
      if FITNESS_SORTING_METHOD=="best_6_in_a_row"
        best = 10.0
        count = 0
        (prediction_distances.length-5).times do
          current = 0.0
          current += prediction_distances[count].abs
          current += prediction_distances[count+1].abs
          current += prediction_distances[count+2].abs
          current += prediction_distances[count+3].abs
          current += prediction_distances[count+4].abs
          current += prediction_distances[count+5].abs
          best = current if best>current
          count += 1
        end
        RAILS_DEFAULT_LOGGER.info("FAverage best_6_in_a_row: #{prediction_distances.inspect}")
        RAILS_DEFAULT_LOGGER.info("FAverage: best #{best} fitness: #{10-best}")
        10-best
      elsif FITNESS_SORTING_METHOD=="cumalative_all" or FITNESS_SORTING_METHOD=="by_investment_strategy"
        all = 0.0
        prediction_distances.each {|a| all+=a.abs}
        RAILS_DEFAULT_LOGGER.info("FAverage cumalative_all #{prediction_distances.inspect}")
        RAILS_DEFAULT_LOGGER.info("FAverage: best #{all} fitness: #{100-all}")
        investment_strategy = InvestmentStrategy.new
        fitness = investment_strategy.get_prediction_details(self)
        fitness_final = fitness.nan? ? 0.00001 : fitness
        RAILS_DEFAULT_LOGGER.info("Fitness finall: #{fitness_final}")
        fitness_final+((100-all)*5)
      elsif FITNESS_SORTING_METHOD=="average_best_5"
        prediction_distances.sort[0..4].each {|a| average+=a.abs}
        10-(average/5)
      elsif FITNESS_SORTING_METHOD=="average_last_5"
        prediction_distances[prediction_distances.length-5..prediction_distances.length-1].each {|a| average+=a.abs}
        RAILS_DEFAULT_LOGGER.info("FAverage last 5: #{prediction_distances[prediction_distances.length-5..prediction_distances.length-1].inspect}")
        RAILS_DEFAULT_LOGGER.info("FAverage: #{average/5} fitness: #{10-(average/5)}")
        10-(average/5)
      elsif FITNESS_SORTING_METHOD=="average_last_10"
        prediction_distances[prediction_distances.length-10..prediction_distances.length-1].each {|a| average+=a.abs}
        RAILS_DEFAULT_LOGGER.info("FAverage last 10: #{prediction_distances[prediction_distances.length-10..prediction_distances.length-1].inspect}")
        RAILS_DEFAULT_LOGGER.info("FAverage: #{average/10} fitness: #{10-(average/10)}")
        10-(average/10)
      elsif FITNESS_SORTING_METHOD=="average_all"
        prediction_distances.each {|a| average+=a.abs}
        RAILS_DEFAULT_LOGGER.info("FAverage all: #{prediction_distances.inspect}")
        RAILS_DEFAULT_LOGGER.info("FAverage: #{average/prediction_distances.length} fitness: #{10-(average/prediction_distances.length)}")
        10-(average/prediction_distances.length)
      end
    else
      0.0
    end
  end

  def import_settings_from_population(population,setting)
    setting.get_genotypes.each do |genotype|
      if genotype.instance_of?(StrategySwitches)
        @selected_inputs = genotype.genes
      elsif genotype.instance_of?(StrategyFloatParameters)
        @inputs_scaling = genotype.genes
      elsif genotype.instance_of?(StrategyIntegerParameters)
        @signal_threshold_settings = genotype.genes
      end
    end
    #Rails.logger.info("Id: #{self.id} Max Epochs: #{self.max_epochs} Desired error: #{self.desired_error} Hidden Neurons: #{@hidden_neurons.inspect} Selected inputs: #{@selected_inputs.inspect} Input scaling: #{@inputs_scaling.inspect}")
  end
end
