class TradingStrategyPopulationsController < ApplicationController
  def show_all_for
    @population = TradingStrategyPopulation.last
  end
end
