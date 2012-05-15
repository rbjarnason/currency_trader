require 'test_helper'

class TradingStrategyPopulationsControllerTest < ActionController::TestCase
  setup do
    @trading_strategy_population = trading_strategy_populations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_strategy_populations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_strategy_population" do
    assert_difference('TradingStrategyPopulation.count') do
      post :create, trading_strategy_population: {  }
    end

    assert_redirected_to trading_strategy_population_path(assigns(:trading_strategy_population))
  end

  test "should show trading_strategy_population" do
    get :show, id: @trading_strategy_population
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_strategy_population
    assert_response :success
  end

  test "should update trading_strategy_population" do
    put :update, id: @trading_strategy_population, trading_strategy_population: {  }
    assert_redirected_to trading_strategy_population_path(assigns(:trading_strategy_population))
  end

  test "should destroy trading_strategy_population" do
    assert_difference('TradingStrategyPopulation.count', -1) do
      delete :destroy, id: @trading_strategy_population
    end

    assert_redirected_to trading_strategy_populations_path
  end
end
