module NdrError
  # Application-wide helpers.
  # TODO: await ndr_ui gem!
  module ApplicationHelper
    # Bootstrap icon tag.
    def glyphicon_tag(type)
      content_tag(:span, '', class: "glyphicon glyphicon-#{type}")
    end

    # Pagination helper for will_paginate:
    def pagination_summary_for(collection)
      page    = collection.current_page
      showing = collection.per_page
      total   = collection.total_entries

      from = (page - 1) * showing + 1
      to   = from + collection.length - 1

      from = [from, total].min
      to   = [to, total].min

      format('Showing %d - %d of %d', from, to, total)
    end
  end
end
