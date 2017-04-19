require 'test_helper'

class MapControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get world" do
    get :world
    assert_response :success
  end

  test "should get china" do
    get :china
    assert_response :success
  end

end
