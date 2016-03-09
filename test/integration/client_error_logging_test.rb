require 'test_helper'

# Ensure host app is able to log errors sent to the API endpoint
class ClientErrorLoggingTest < ActionDispatch::IntegrationTest
  def setup
    NdrError::Fingerprint.delete_all
    NdrError::Log.delete_all
  end

  test 'should log client exceptions' do
    assert_difference(-> { NdrError::Log.count }, 2) do
      2.times { visit '/disaster/cause_client' }
    end

    error_logs = NdrError::Log.all
    assert error_logs.map(&:error_fingerprint).uniq.one?
    error_log = error_logs.first

    assert_equal 'NdrError::JavascriptError', error_log.error_class
    assert_equal "ReferenceError: Can't find variable: fooBarBaz", error_log.description
  end
end
