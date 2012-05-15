require 'test_helper'

class TradingAccountsControllerTest < ActionController::TestCase
  setup do
    @trading_account = trading_accounts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_accounts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_account" do
    assert_difference('TradingAccount.count') do
      post :create, trading_account: {  }
    end

    assert_redirected_to trading_account_path(assigns(:trading_account))
  end

  test "should show trading_account" do
    get :show, id: @trading_account
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_account
    assert_response :success
  end

  test "should update trading_account" do
    put :update, id: @trading_account, trading_account: {  }
    assert_redirected_to trading_account_path(assigns(:trading_account))
  end

  test "should destroy trading_account" do
    assert_difference('TradingAccount.count', -1) do
      delete :destroy, id: @trading_account
    end

    assert_redirected_to trading_accounts_path
  end
end
