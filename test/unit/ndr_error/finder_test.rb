require 'test_helper'

module NdrError
  # Unit test finder mixin
  class FinderTest < ActiveSupport::TestCase
    include Finder

    test 'should search by username correctly' do
      error = simulate_raise(Exception, 'the error 1', [])
      print = error.error_fingerprint
      error.update_attribute(:user_id, 'johnsmith')

      assert search(['john']).index(print)
      assert search(['JOHN']).index(print)
      assert search(['johnsmith']).index(print)
      assert search(%w(john smith)).index(print)
      assert search(%w(john jack)).index(print)
      refute search(%w(jack smyth)).index(print)
    end

    test 'should search by error type correctly' do
      error = simulate_raise(RuntimeError, 'the annoying error 123', [])
      print = error.error_fingerprint

      assert search(['annoying']).index(print)
      assert search(['error']).index(print)
      assert search(['123']).index(print)
      assert search(%w(123 error)).index(print)
      assert search(['RUNTIME']).index(print)
      assert search(['runtimeerror']).index(print)
      assert search(%w(missing error)).index(print)
      refute search(['annoyance']).index(print)
      refute search(['exception']).index(print)
    end

    test 'should search by md5 correctly' do
      error = simulate_raise(RuntimeError, 'the annoying error 123', [])
      print = error.error_fingerprint
      chunk = print.id

      assert search([chunk[0, 3]]).index(print)
      assert search([chunk[1, 5]]).index(print)
      assert search([chunk[2, 7]]).index(print)
      assert search([chunk[3, 9]]).index(print)

      assert search([chunk]).index(print)
      refute search([chunk.reverse]).index(print)
    end

    test 'should order correctly when searching' do
      print1 = simulate_raise(Exception, 'an old exception', []).error_fingerprint
      print2 = simulate_raise(RuntimeError, 'old but different', []).error_fingerprint
      print3 = simulate_raise(Exception, 'not old at all', []).error_fingerprint

      results = search([print2.id, 'old'])
      assert_equal [print2, print3, print1], results
    end
  end
end
