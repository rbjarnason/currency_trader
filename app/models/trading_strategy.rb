class TradingStrategy < ActiveRecord::Base
  has_and_belongs_to_many :trading_strategy_sets
end
