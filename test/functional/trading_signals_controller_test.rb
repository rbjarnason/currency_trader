require 'test_helper'

class TradingSignalsControllerTest < ActionController::TestCase
  setup do
    @trading_signal = trading_signals(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_signals)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_signal" do
    assert_difference('TradingSignal.count') do
      post :create, trading_signal: {  }
    end

    assert_redirected_to trading_signal_path(assigns(:trading_signal))
  end

  test "should show trading_signal" do
    get :show, id: @trading_signal
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_signal
    assert_response :success
  end

  test "should update trading_signal" do
    put :update, id: @trading_signal, trading_signal: {  }
    assert_redirected_to trading_signal_path(assigns(:trading_signal))
  end

  test "should destroy trading_signal" do
    assert_difference('TradingSignal.count', -1) do
      delete :destroy, id: @trading_signal
    end

    assert_redirected_to trading_signals_path
  end
end
