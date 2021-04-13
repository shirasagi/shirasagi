module Gws::Presence::UserHelper
  extend ActiveSupport::Concern

  def user_presence_state_selector(item)
    user_presence = item.user_presence(@cur_site)
    url = gws_presence_apis_user_path(id: item.id) + ".json"

    h = []
    h << "<div class=\"presence-state-selector\" data-id=\"#{item.id}\" data-url=\"#{url}\" style=\"display: none;\">"
    user_presence.state_options.each do |k, v|
      s = (user_presence.state.to_s == v.to_s) ? "" : 'style="visibility:hidden"'
      h << "<p class=\"#{user_presence.state_style(v)}\" data-value=\"#{v}\">"
      h << "<i class=\"material-icons md-16\ selected-icon\" #{s}>done</i>"
      h << "<span>#{k}</span>"
      h << '</p>'
    end
    h << '</div>'
    h.join
  end

  def ajax_text_field_tag(name, value, data_id, data_url)
    data_original_tag = link_to(value, "",
      "class" => "ajax-text-field",
      "data-tag-state" => "original",
      "data-name" => name,
      "data-id" => data_id
    )
    data_form_tag = text_field_tag(name, "",
      "class" => "ajax-text-field",
      "autocomplete" => "off",
      "data-tag-state" => "form",
      "data-id" => data_id,
      "data-url" => data_url
    )
    link_to(value, "",
      "class" => "ajax-text-field",
      "autocomplete" => "off",
      "data-original-tag" => data_original_tag,
      "data-form-tag" => data_form_tag,
      "data-tag-state" => "original",
      "data-name" => name,
      "data-id" => data_id
    )
  end
end
