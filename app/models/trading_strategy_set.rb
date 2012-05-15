class TradingStrategySet < ActiveRecord::Base
  has_many :trading_strategies, :dependent => :destroy
  belongs_to :trading_strategy_population
end
