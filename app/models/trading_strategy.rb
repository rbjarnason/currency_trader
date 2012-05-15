class TradingStrategy < ActiveRecord::Base
  belongs_to :trading_strategy_template
  belongs_to :trading_strategy_set
  has_many   :trading_signals, :dependent => :delete_all

  # Parameters
  # 0: Time to look back in ms (10000)
  # 1: Magnitude of change since time in percent (0.01)
  # 2: Type of trading signal (Buy or Sell)
  serialize :parameters, Array(10)

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
