require 'test_helper'

class TradingSimulationsControllerTest < ActionController::TestCase
  setup do
    @trading_simulation = trading_simulations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_simulations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_simulation" do
    assert_difference('TradingSimulation.count') do
      post :create, trading_simulation: {  }
    end

    assert_redirected_to trading_simulation_path(assigns(:trading_simulation))
  end

  test "should show trading_simulation" do
    get :show, id: @trading_simulation
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_simulation
    assert_response :success
  end

  test "should update trading_simulation" do
    put :update, id: @trading_simulation, trading_simulation: {  }
    assert_redirected_to trading_simulation_path(assigns(:trading_simulation))
  end

  test "should destroy trading_simulation" do
    assert_difference('TradingSimulation.count', -1) do
      delete :destroy, id: @trading_simulation
    end

    assert_redirected_to trading_simulations_path
  end
end
