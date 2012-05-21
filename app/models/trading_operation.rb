class TradingOperation < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :quote_target
  belongs_to :trading_account
  belongs_to :trading_strategy_population
  has_many :trading_positions
end
