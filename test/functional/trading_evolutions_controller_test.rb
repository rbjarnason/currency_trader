require 'test_helper'

class TradingEvolutionsControllerTest < ActionController::TestCase
  setup do
    @trading_evolution = trading_evolutions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_evolutions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_evolution" do
    assert_difference('TradingEvolution.count') do
      post :create, trading_evolution: {  }
    end

    assert_redirected_to trading_evolution_path(assigns(:trading_evolution))
  end

  test "should show trading_evolution" do
    get :show, id: @trading_evolution
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_evolution
    assert_response :success
  end

  test "should update trading_evolution" do
    put :update, id: @trading_evolution, trading_evolution: {  }
    assert_redirected_to trading_evolution_path(assigns(:trading_evolution))
  end

  test "should destroy trading_evolution" do
    assert_difference('TradingEvolution.count', -1) do
      delete :destroy, id: @trading_evolution
    end

    assert_redirected_to trading_evolutions_path
  end
end
