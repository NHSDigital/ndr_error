require 'test_helper'

# Test integration with the host application
class ErrorViewingTest < ActionDispatch::IntegrationTest
  def setup
    NdrError::Fingerprint.delete_all
    NdrError::Log.delete_all
  end

  test 'should use authentication' do
    NdrError.stubs(check_current_user_authentication: ->(_context) { false })

    get '/fingerprinting/errors'

    assert_redirected_to '/'
    assert_equal flash[:error], 'You are not authenticated.'
  end

  test 'should use the layout of the engine, not that of the host app' do
    get '/fingerprinting/errors'

    refute response.body.include? "This is the Dummy App's layout file!"
    assert response.body.include? 'Error Logging by NDR'
  end

  test 'should be able to view a list of exceptions' do
    simulate_raise(StandardError, 'Doh!', [])
    simulate_raise(RuntimeError, 'Whoops!', [])

    get '/fingerprinting/errors'

    assert response.body.include? 'StandardError: Doh!'
    assert response.body.include? 'RuntimeError: Whoops!'
  end

  test 'should be able to view details of an exception' do
    print1 = simulate_raise(StandardError, 'Doh!', [], user_id: 'Bob Jones').error_fingerprint
    print2 = simulate_raise(StandardError, 'Doh!', [], user_id: 'Sam Smith').error_fingerprint

    assert_equal print1, print2

    get "/fingerprinting/errors/#{print1.error_fingerprintid}"

    assert response.body.include? 'Doh!'
    assert response.body.include? '1 similar error stored'
    assert response.body.include? 'Bob Jones'
  end

  test 'should redirect to listing when error not found' do
    get '/fingerprinting/errors/notafingerprint'

    assert_redirected_to '/fingerprinting/errors'
    assert_equal flash[:error], 'Unknown or deleted error fingerprint'
  end

  test 'should be able to edit details of an exception' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint

    get "/fingerprinting/errors/#{print1.error_fingerprintid}/edit"

    assert response.body.include? 'Ticket URL'
    assert response.body.include? 'Update'
    assert response.body.include? 'Cancel'
  end

  test 'should be able to update reference url of a fingerprint' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint
    params = { error_fingerprint: { ticket_url: 'http://google.com' } }

    put "/fingerprinting/errors/#{print1.error_fingerprintid}", params

    assert_redirected_to "/fingerprinting/errors/#{print1.error_fingerprintid}"
    assert_equal 'The Error Fingerprint was successfully updated!', flash[:notice]

    get "/fingerprinting/errors/#{print1.error_fingerprintid}"
    assert response.body.include? 'View ticket'
  end

  test 'should protect log purging' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint

    NdrError.stubs(check_current_user_permissions: ->(_context) { false })

    delete "/fingerprinting/errors/#{print1.error_fingerprintid}"

    assert_redirected_to '/fingerprinting/errors'
    assert_equal flash[:error], 'You do not have the required permissions for that.'
  end

  test 'should be able to purge logs' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint

    delete "/fingerprinting/errors/#{print1.error_fingerprintid}"

    assert_redirected_to '/fingerprinting/errors'
    assert_equal 'Fingerprint purged!', flash[:error]
    assert_equal 0, print1.error_logs.reload.length

    get "/fingerprinting/errors/#{print1.error_fingerprintid}"

    # Should redirect to filtered listing if there are no logs to view:
    assert_redirected_to "/fingerprinting/errors?q=#{print1.error_fingerprintid}"
    assert_equal flash[:error], 'No matching Logs exist for that Fingerprint!'
  end
end
