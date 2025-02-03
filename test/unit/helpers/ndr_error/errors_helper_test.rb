require 'test_helper'

module NdrError
  # Test helpers
  class ErrorsHelperTest < ActionView::TestCase
    test 'search_matches' do
      assert_equal 'hello world', search_matches('hello world', [])
      assert_equal 'hello world', search_matches('hello world', ['cruel'])

      expected = 'hello <strong class="text-danger">world</strong>'
      actual   = search_matches('hello world', ['world'])

      assert actual.html_safe?, 'was not html_safe'
      assert_equal expected, actual
    end

    test 'highlighted_trace_for' do
      error = mock(backtrace: %w[a b c], application_trace: %w[a c])

      actual   = highlighted_trace_for(error)
      expected =
        %w[
          <span\ class="trace-item">a</span>
          <span\ class="trace-item\ stack-only">b</span>
          <span\ class="trace-item">c</span>
        ]

      assert_equal expected, actual
    end

    test 'latest_user_for without occurence' do
      print = mock(latest_occurrence: nil)

      actual   = latest_user_for(print, ['bob'])
      expected = '<span class="text-muted">N/A</span>'

      assert_equal expected, actual
    end

    test 'latest_user_for with occurence' do
      print = mock(latest_occurrence: mock(user_id: 'bobjones'))

      actual   = latest_user_for(print, ['bob'])
      expected = '<span class="text-muted"><strong class="text-danger">bob</strong>jones</span>'

      assert_equal expected, actual
    end

    test 'multiple_occurrences_badge_for without multiple occurences' do
      print = mock(count: 1)
      assert_nil multiple_occurrences_badge_for(print)
    end

    test 'multiple_occurrences_badge_for with multiple occurences' do
      print = mock(created_at: Date.parse('2015-01-01'))
      print.stubs(count: 3)

      actual   = multiple_occurrences_badge_for(print)
      expected = '<span class="badge badge-info" data-bs-placement="right"' \
                 ' data-bs-toggle="tooltip" data-bs-title="Since 2015-01-01">+ 2</span>'

      assert_dom_equal expected, actual
    end

    test 'digest_for' do
      print = mock(id: '123456')

      expected = '<span class="text-muted">12<strong class="text-danger">345</strong>6</span>'
      actual   = digest_for(print, '345')

      assert_equal expected, actual
    end

    test 'sorted_parameters_for' do
      error = mock(parameters: { b: 1, c: 2, a: 3 })
      assert_equal [[:a, 3], [:b, 1], [:c, 2]], sorted_parameters_for(error)
    end
  end
end
