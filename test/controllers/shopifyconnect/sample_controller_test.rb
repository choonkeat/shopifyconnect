require 'test_helper'

module Shopifyconnect
  class SampleControllerTest < ActionController::TestCase
    test "should get webhook" do
      get :webhook
      assert_response :success
    end

    test "should get js" do
      get :js
      assert_response :success
    end

  end
end
