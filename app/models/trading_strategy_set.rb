class TradingStrategySet < ActiveRecord::Base
  has_and_belongs_to_many :trading_strategies
  has_and_belongs_to_many :trading_operations
end
