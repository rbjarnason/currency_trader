require 'test_helper'

class TradingOperationsControllerTest < ActionController::TestCase
  setup do
    @trading_operation = trading_operations(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_operations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_operation" do
    assert_difference('TradingOperation.count') do
      post :create, trading_operation: {  }
    end

    assert_redirected_to trading_operation_path(assigns(:trading_operation))
  end

  test "should show trading_operation" do
    get :show, id: @trading_operation
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_operation
    assert_response :success
  end

  test "should update trading_operation" do
    put :update, id: @trading_operation, trading_operation: {  }
    assert_redirected_to trading_operation_path(assigns(:trading_operation))
  end

  test "should destroy trading_operation" do
    assert_difference('TradingOperation.count', -1) do
      delete :destroy, id: @trading_operation
    end

    assert_redirected_to trading_operations_path
  end
end
