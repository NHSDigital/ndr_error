require 'test_helper'

module NdrError
  # Test our fuzzing / digest creation:
  class FuzzingTest < ActiveSupport::TestCase
    # Dummy class for testing Fuzzing mixin
    class Fuzzable
      include NdrError::Fuzzing

      def client_error?
        false
      end
    end

    def setup
      @fuzzable = Fuzzable.new
    end

    test 'should fuzz descriptions correctly' do
      description = "TemplateError: undefined method `clean' for [\"XYZ\", \"ABC\"]:Array"
      refute @fuzzable.send(:fuzz_description, description).include?('XYZ')

      # Should obfuscate objectids:
      assert_equal @fuzzable.fuzz('#<EUserBatch:0x123e12345>', []), @fuzzable.fuzz('#<EUserBatch:0x134a45639>', [])
    end

    test 'should fuzz Rails root directory from backtraces' do
      trace = @fuzzable.send(:fuzz_backtrace, [Rails.root.join('app').to_s])
      assert_equal 'Rails.root/app', trace
    end

    test 'should fuzz gem differences from backtraces' do
      # Should fuzz gem paths:
      trace = @fuzzable.send(:fuzz_backtrace, [Gem.path.first + '/app'])
      assert_equal 'Gem.path/app', trace

      # Should remove gem version number when fuzzing gem paths
      line = Gem.path.first + "/gems/evil-1.4.3/lib/evil/file.rb:623:in `method'"
      assert_equal "Gem.path/gems/evil-/lib/evil/file.rbin `method'", @fuzzable.send(:fuzz_backtrace, [line])
    end

    test 'should fuzz LOAD_PATH from backtraces' do
      # Should fuzz load path entries:
      trace = @fuzzable.send(:fuzz_backtrace, [$LOAD_PATH.first + '/app'])
      refute trace.include?($LOAD_PATH.first)
    end

    test 'should fuzz line numbers from backtraces' do
      # Should fuzz line numbers:
      trace = @fuzzable.send(:fuzz_backtrace, ['app/myfile.rb:12: in function'])
      assert_equal 'app/myfile.rb in function', trace
    end

    test 'should fuzz compiled template / partial IDs from backtraces' do
      template = ActionView::Template.new('test template', 'template.html.erb', nil, {})
      compiled = template.send(:method_name) # The method name of the template once compiled

      assert_equal '_template_html_erb__COMPILED_ID', @fuzzable.send(:fuzz_backtrace, [compiled])

      partial  = ActionView::Template.new('test partial', '_partial.html.erb', nil, {})
      compiled = partial.send(:method_name) # The method name of the partial once compiled

      assert_equal '__partial_html_erb__COMPILED_ID', @fuzzable.send(:fuzz_backtrace, [compiled])
    end

    test 'should fuzz compiled callbacks from backtraces' do
      trace = @fuzzable.send(:fuzz_backtrace, ['_run__2058915813__process_action__1931044129__callbacks'])
      assert_equal '_run__COMPILED_ID__process_action__COMPILED_ID__callbacks', trace
    end
    
    test '#fuzz_backtrace should be consistent with client errors' do
      @fuzzable.stubs(client_error?: true)
      assert_equal @fuzzable.send(:fuzz_backtrace, ['abc']), @fuzzable.send(:fuzz_backtrace, ['bcd'])
    end

    test 'fuzzing should be sensitive to client error descriptions' do
      @fuzzable.stubs(client_error?: true)
      assert_equal @fuzzable.fuzz('test', []), @fuzzable.fuzz('test', [])
      refute_equal @fuzzable.fuzz('test', []), @fuzzable.fuzz('zest', [])
    end

    test 'fuzzing should be not sensitive to client error backtraces' do
      @fuzzable.stubs(client_error?: true)
      assert_equal @fuzzable.fuzz('test', %w(t e s t)), @fuzzable.fuzz('test', %w(t e s t))
      assert_equal @fuzzable.fuzz('test', %w(t e s t)), @fuzzable.fuzz('test', %w(e s t e))
    end
  end
end
