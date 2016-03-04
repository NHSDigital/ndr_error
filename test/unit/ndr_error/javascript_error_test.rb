require 'test_helper'

module NdrError
  # Unit Test Log.
  class JavaScriptErrorTest < ActiveSupport::TestCase
    test 'should set backtrace' do
      params = {
        "message"=>"ReferenceError: adfgrdfgkljh is not defined",
        "source"=>"http://localhost:3000",
        "lineno"=>"49",
        "colno"=>"1",
        "stack"=>
        "stack_values\nline 1\nline 2\nline 3"
      }
      error = JavascriptError.new(params)

      assert_equal "ReferenceError: adfgrdfgkljh is not defined", error.message
      assert_equal 4, error.backtrace.length

    end
  end
end
