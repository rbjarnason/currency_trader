require 'test_helper'

class TradingStrategiesControllerTest < ActionController::TestCase
  setup do
    @trading_strategy = trading_strategies(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_strategies)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_strategy" do
    assert_difference('TradingStrategy.count') do
      post :create, trading_strategy: {  }
    end

    assert_redirected_to trading_strategy_path(assigns(:trading_strategy))
  end

  test "should show trading_strategy" do
    get :show, id: @trading_strategy
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_strategy
    assert_response :success
  end

  test "should update trading_strategy" do
    put :update, id: @trading_strategy, trading_strategy: {  }
    assert_redirected_to trading_strategy_path(assigns(:trading_strategy))
  end

  test "should destroy trading_strategy" do
    assert_difference('TradingStrategy.count', -1) do
      delete :destroy, id: @trading_strategy
    end

    assert_redirected_to trading_strategies_path
  end
end
