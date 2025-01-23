module NdrError
  # Application-wide helpers.
  # TODO: await ndr_ui gem!
  module ApplicationHelper
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
