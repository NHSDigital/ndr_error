module NdrError
  # Error-specific view helpers
  module ErrorsHelper
    def search_matches(string, keywords)
      return string if keywords.blank?
      highlight(string.to_s, keywords, highlighter: '<strong class="text-danger">\1</strong>')
    end

    def highlighted_trace_for(error)
      highlighting = error.application_trace

      error.backtrace.map do |line|
        css_classes = 'trace-item'
        css_classes << ' stack-only' unless highlighting.include?(line)

        content_tag(:span, line, class: css_classes)
      end
    end

    def latest_timestamp_for(fingerprint)
      fingerprint.updated_at.to_formatted_s(:db)
    end

    def latest_user_for(fingerprint, search)
      latest = fingerprint.latest_occurrence
      text   = latest ? search_matches(latest.user_id, search) : 'N/A'

      content_tag(:span, text, class: 'text-muted')
    end

    def multiple_occurrences_badge_for(fingerprint)
      return unless fingerprint.count > 1

      text = "+ #{fingerprint.count - 1}"
      opts = {
        'class'          => 'badge badge-info',
        'data-toggle'    => 'tooltip',
        'data-placement' => 'right',
        'title'          => "Since #{fingerprint.created_at.to_formatted_s(:db)}"
      }

      content_tag(:span, text, opts)
    end

    def similar_error_link(error)
      user = error.user_id && content_tag(:span, error.user_id, class: 'text-muted')
      text = safe_join([user, error.created_at.to_formatted_s(:db)].compact, ' - ')

      bootstrap_list_link_to text, error_fingerprint_path(error.error_fingerprint, log_id: error)
    end

    def downstream_fingerprint_link(print)
      hash = content_tag(:span, print.id, class: 'text-muted')
      text = print.error_logs.first.try(:error_class) || 'N/A'

      bootstrap_list_link_to hash + ' - ' + text, error_fingerprint_path(print)
    end

    def ticket_link_for(fingerprint, small = false)
      text = bootstrap_icon_tag('asterisk', :bi) + ' View ticket'
      css  = 'btn btn-outline-secondary'
      css << ' btn-xs' if small

      url = fingerprint.ticket_url
      link_to(text, /^http/i =~ url ? url : "http://#{url}", class: css)
    end

    def edit_button_for(fingerprint)
      css   = 'btn btn-outline-secondary'
      text  = bootstrap_icon_tag('pencil', :bi) + ' Edit Ticket'

      link_to(text, edit_error_fingerprint_path(fingerprint), class: css)
    end

    def purge_button_for(fingerprint)
      css   = 'btn btn-danger'
      text  = bootstrap_icon_tag('trash-fill', :bi) + ' Purge'

      options = {
        'method'       => :delete,
        'class'        => css,
        'data-confirm' => 'Delete all logs of this error? - only the fingerprint will be kept.'
      }

      link_to(text, error_fingerprint_path(fingerprint), options)
    end

    def previous_button_for(error)
      css = 'btn btn-outline-secondary'
      css << ' disabled' if error.nil?
      text = bootstrap_icon_tag('chevron-left', :bi)
      path = error.nil? ? '#' : error_fingerprint_path(error.error_fingerprint, log_id: error)

      link_to(text, path, class: css)
    end

    def next_button_for(error)
      css = 'btn btn-outline-secondary'
      css << ' disabled' if error.nil?
      text = bootstrap_icon_tag('chevron-right', :bi)
      path = error.nil? ? '#' : error_fingerprint_path(error.error_fingerprint, log_id: error)

      link_to(text, path, class: css)
    end

    def link_to_fingerprint(fingerprint, latest)
      text = truncate(latest.error_string, length: 120)
      link_to search_matches(text, @keywords), error_fingerprint_path(fingerprint)
    end

    def digest_for(fingerprint, search)
      digest = search_matches(fingerprint.id, search)
      content_tag(:span, digest, class: 'text-muted')
    end

    def sorted_parameters_for(error)
      error.parameters.to_a.sort_by { |key, _value| key.to_s }
    end
  end
end
