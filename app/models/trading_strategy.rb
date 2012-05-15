class TradingStrategy < ActiveRecord::Base
  belongs_to :trading_strategy_template
  belongs_to :trading_strategy_set
  has_many   :trading_signals, :dependent => :delete_all

  # Parameters
  # 0: Time to look back in ms (10000)
  # 1: Magnitude of change since time in percent (0.01)
  # 2: Type of trading signal (Buy or Sell)
  serialize :switch_parameters, Array(10)
  serialize :float_parameters, Array(10)
  serialize :integer_parameters, Array(10)

  def import_parameters(parameters)
    switch_parameters = parameters[:switch]
    float_parameters = parameters[:float]
    integer_parameters = parameters[:integer]
    @strategy_buy_short = @switch_parameters[0]
    @how_far_back_days = @integer_parameters[0]

  end

  def evaluate_trade
    quote_value_change = current_quote_value-quote_value_in_the_past(parameters[0])
    if (quote_value_change/current_quote_value).abs>parameters[1]
      generate_trading_signal(parameters[2])
    end
  end

  private

  def current_quote_value
  end

  def quote_value_in_the_past
  end

  def generate_trading_signal(signal)
     TradingSignal.create(:trading_strategy_id=>self.id, :signal=>signal)
  end
end
