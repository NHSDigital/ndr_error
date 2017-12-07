require 'test_helper'

# Ensure host app is able to log errors (configured with bundled middleware)
class ErrorLoggingTest < ActionDispatch::IntegrationTest
  # Used to capture evidence of callbacks being run:
  class << self
    def callback_invocations
      @callback_invocations ||= []
    end
  end

  def setup
    NdrError::Fingerprint.delete_all
    NdrError::Log.delete_all

    # Reset to a boring default:
    NdrError.exception_app_callback = ->(_request, _exception) { true }
  end

  test 'should create an error log record when an error is raised, and display render message' do
    # Register callbacks being executed:
    NdrError.exception_app_callback = lambda do |request, exception|
      ErrorLoggingTest.callback_invocations << [request, exception]
    end

    assert_difference('ErrorLoggingTest.callback_invocations.length', 1) do
      assert_application_fails_gracefully('boom')
    end

    matching_error = NdrError::Log.all.detect do |error|
      ('RuntimeError' == error.error_class) && ('boom' == error.description)
    end

    assert matching_error, 'no error log was created!'
  end

  test 'should not create an error log record if callback returns false' do
    NdrError.exception_app_callback = ->(_request, _exception) { false }

    # No error_log should be created:
    assert_application_fails_gracefully('boom', 0)
  end

  test 'should fallback if error logging fails' do
    # Raise an exception whilst handling an exception!
    NdrError.exception_app_callback = ->(_request, _exception) { fail 'uh oh' }

    # We expect fallback notification in webapp logs:
    Rails.logger.expects(:warn).with do |message|
      message.include?('NdrError failed to log an exception!') && message.include?('uh oh')
    end

    # No error will be created, but we should still get the 500 page:
    assert_application_fails_gracefully('boom', 0)
  end

  private

  def assert_application_fails_gracefully(message, log_count = 1)
    assert_difference('NdrError::Log.count', log_count) do
      visit "/disaster/cause/?message=#{message}"

      assert page.body.include? 'This is the 500 page for DummyApp.'
      assert_equal 500, page.status_code
    end
  end
end
