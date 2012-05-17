class TradingStrategyPopulationsController < InheritedResources::Base
  def show_all_for
    @population = TradingStrategyPopulation.find(params[:id])
  end
end
