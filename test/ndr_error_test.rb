require 'test_helper'

# Top level test.
class NdrErrorTest < ActiveSupport::TestCase
  test 'should have extracted filtering settings from the host app' do
    assert NdrError.filtered_parameters.include?(:dummy_app_test_sensitive_parameter)
  end
end
