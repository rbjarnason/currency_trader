require 'test_helper'

class TradingStrategySetsControllerTest < ActionController::TestCase
  setup do
    @trading_strategy_set = trading_strategy_sets(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_strategy_sets)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_strategy_set" do
    assert_difference('TradingStrategySet.count') do
      post :create, trading_strategy_set: {  }
    end

    assert_redirected_to trading_strategy_set_path(assigns(:trading_strategy_set))
  end

  test "should show trading_strategy_set" do
    get :show, id: @trading_strategy_set
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_strategy_set
    assert_response :success
  end

  test "should update trading_strategy_set" do
    put :update, id: @trading_strategy_set, trading_strategy_set: {  }
    assert_redirected_to trading_strategy_set_path(assigns(:trading_strategy_set))
  end

  test "should destroy trading_strategy_set" do
    assert_difference('TradingStrategySet.count', -1) do
      delete :destroy, id: @trading_strategy_set
    end

    assert_redirected_to trading_strategy_sets_path
  end
end
