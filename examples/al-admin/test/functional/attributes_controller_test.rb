require File.dirname(__FILE__) + '/../test_helper'
require 'attributes_controller'

# Re-raise errors caught by the controller.
class AttributesController; def rescue_action(e) raise e end; end

class AttributesControllerTest < Test::Unit::TestCase
  def setup
    @controller = AttributesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
