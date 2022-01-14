require 'test_helper'

# Test integration with the host application
class ErrorViewingTest < ActionDispatch::IntegrationTest
  def setup
    NdrError::Fingerprint.delete_all
    NdrError::Log.delete_all
  end

  test 'should use authentication' do
    NdrError.stubs(check_current_user_authentication: ->(_context) { false })

    visit '/fingerprinting/errors'

    assert_current_path('/')
    assert page.has_content?('You are not authenticated.')
  end

  test 'should use the layout of the engine, not that of the host app' do
    visit '/fingerprinting/errors'

    refute page.body.include? "This is the Dummy App's layout file!"
    assert page.body.include? 'Error Logging by NDR'
  end

  test 'should be able to view a list of exceptions' do
    simulate_raise(StandardError, 'Doh!', [])
    simulate_raise(RuntimeError, 'Whoops!', [])

    visit '/fingerprinting/errors'

    assert page.body.include? 'StandardError: Doh!'
    assert page.body.include? 'RuntimeError: Whoops!'
  end

  test 'should be redirected to view a particular occurence' do
    log       = simulate_raise(StandardError, 'Doh!', [], user_id: 'Bob Jones')
    base_path = "/fingerprinting/errors/#{log.error_fingerprintid}"

    visit base_path
    assert page.has_content? 'Doh!'
    assert current_url.ends_with? "#{base_path}?log_id=#{log.id}"
  end

  test 'should not be able to view a bare fingerprint' do
    log       = simulate_raise(StandardError, 'Doh!', [], user_id: 'Bob Jones')
    base_path = "/fingerprinting/errors/#{log.error_fingerprintid}"

    log.error_fingerprint.purge!

    visit base_path
    assert_current_path('/fingerprinting/errors', ignore_query: true)
    assert page.has_content? 'No matching Logs exist for that Fingerprint!'
  end

  test 'should be able to view details of an exception' do
    print1 = simulate_raise(StandardError, 'Doh!', [], user_id: 'Bob Jones').error_fingerprint
    print2 = simulate_raise(StandardError, 'Doh!', [], user_id: 'Sam Smith').error_fingerprint

    assert_equal print1, print2

    visit "/fingerprinting/errors/#{print1.error_fingerprintid}"

    assert page.body.include? 'Doh!'
    assert page.body.include? '1 Similar Error Stored'
    assert page.body.include? 'Bob Jones'
  end

  test 'should not see similar errors options for unique error' do
    print1 = simulate_raise(StandardError, 'Doh!', [], user_id: 'Bob Jones').error_fingerprint

    visit "/fingerprinting/errors/#{print1.error_fingerprintid}"

    assert page.body.include? 'Doh!'
    refute page.body.include? 'Similar Error'
    assert page.body.include? 'Bob Jones'
  end

  test 'should redirect to listing when error not found' do
    visit '/fingerprinting/errors/notafingerprint'

    assert_current_path('/fingerprinting/errors')
    assert page.has_content?('Unknown or deleted error fingerprint')
  end

  test 'should be able to edit details of an exception' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint

    visit "/fingerprinting/errors/#{print1.error_fingerprintid}/edit"

    assert page.body.include? 'Ticket URL'
    assert page.body.include? 'Update'
    assert page.body.include? 'Cancel'
  end

  test 'should be able to update reference url of a fingerprint' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint

    visit "/fingerprinting/errors/#{print1.error_fingerprintid}/edit"
    fill_in('Ticket URL', with: 'http://google.com')
    click_button 'Update'

    assert_current_path("/fingerprinting/errors/#{print1.error_fingerprintid}", ignore_query: true)
    assert page.has_content?('The Error Fingerprint was successfully updated!')

    get "/fingerprinting/errors/#{print1.error_fingerprintid}"
    assert page.body.include? 'View ticket'
  end

  test 'should be able to purge logs' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint

    visit "/fingerprinting/errors/#{print1.error_fingerprintid}"

    accept_alert(/Delete all logs of this error?/) do
      click_link 'Purge'
    end

    # Don't use assert_equal '/fingerprinting/errors', current_path
    # because this has race conditions
    assert_current_path('/fingerprinting/errors')
    assert page.has_content?('Fingerprint purged!')
    assert_equal 0, print1.error_logs.not_deleted.count

    visit "/fingerprinting/errors/#{print1.error_fingerprintid}"

    # Should redirect to filtered listing if there are no logs to view:
    assert_current_path("/fingerprinting/errors?q=#{print1.error_fingerprintid}")
    assert page.has_content?('No matching Logs exist for that Fingerprint!')
  end

  test 'should be able to view causal error' do
    print1 = simulate_raise(StandardError, 'Doh!', []).error_fingerprint
    print2 = simulate_raise(StandardError, 'Oh!', []).error_fingerprint

    print2.causal_error_fingerprint = print1
    print2.save!

    down_link = '1 Downstream Error Stored'
    up_link   = 'View Cause'

    visit "/fingerprinting/errors/#{print2.error_fingerprintid}"

    assert page.has_no_content? down_link
    click_link up_link

    assert_current_path(Regexp.new(".*/#{Regexp.escape(print1.id)}"))
    assert page.has_content? down_link
    assert page.has_no_link? up_link
  end
end
