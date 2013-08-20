class TradingStrategyPopulationsController < ApplicationController
  def show_all_for
    @population = TradingStrategyPopulation.find(params[:id])
  end
end
