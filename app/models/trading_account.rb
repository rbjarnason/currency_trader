class TradingAccount < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :trading_operations
  attr_accessible :name
end
