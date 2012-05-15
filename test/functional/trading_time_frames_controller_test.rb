require 'test_helper'

class TradingTimeFramesControllerTest < ActionController::TestCase
  setup do
    @trading_time_frame = trading_time_frames(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:trading_time_frames)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create trading_time_frame" do
    assert_difference('TradingTimeFrame.count') do
      post :create, trading_time_frame: {  }
    end

    assert_redirected_to trading_time_frame_path(assigns(:trading_time_frame))
  end

  test "should show trading_time_frame" do
    get :show, id: @trading_time_frame
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @trading_time_frame
    assert_response :success
  end

  test "should update trading_time_frame" do
    put :update, id: @trading_time_frame, trading_time_frame: {  }
    assert_redirected_to trading_time_frame_path(assigns(:trading_time_frame))
  end

  test "should destroy trading_time_frame" do
    assert_difference('TradingTimeFrame.count', -1) do
      delete :destroy, id: @trading_time_frame
    end

    assert_redirected_to trading_time_frames_path
  end
end
