require 'test_helper'

module NdrError
  # Test application-wide helpers
  class ApplicationHelperTest < ActionView::TestCase
    test 'glyphicon_tag' do
      expected = '<span class="glyphicon glyphicon-padlock"></span>'
      actual   = glyphicon_tag(:padlock)
      assert_equal expected, actual
    end

    test 'pagination_summary_for within range' do
      collection = (1..10).to_a.paginate(per_page: 3, page: 2)
      assert_equal 'Showing 4 - 6 of 10', pagination_summary_for(collection)
    end

    test 'pagination_summary_for outside of range' do
      collection = (1..10).to_a.paginate(per_page: 3, page: 4)
      assert_equal 'Showing 10 - 10 of 10', pagination_summary_for(collection)
    end
  end
end
