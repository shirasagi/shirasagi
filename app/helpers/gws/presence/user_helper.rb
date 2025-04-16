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

  #def ajax_text_field_tag(name, value, data_id, data_url)
  #  data_original_tag = link_to(value, "",
  #    "class" => "ajax-text-field",
  #    "data-tag-state" => "original",
  #    "data-name" => name,
  #    "data-id" => data_id
  #  )
  #  data_form_tag = text_field_tag(name, "",
  #    "class" => "ajax-text-field",
  #    "autocomplete" => "off",
  #    "data-tag-state" => "form",
  #    "data-id" => data_id,
  #    "data-url" => data_url
  #  )
  #  link_to(value, "",
  #    "class" => "ajax-text-field",
  #    "autocomplete" => "off",
  #    "data-original-tag" => data_original_tag,
  #    "data-form-tag" => data_form_tag,
  #    "data-tag-state" => "original",
  #    "data-name" => name,
  #    "data-id" => data_id
  #  )
  #end

  def render_edit_presence_plan(item)
    frame_id = "presence-plan-#{SecureRandom.uuid}"
    user_presence = item.user_presence(@cur_site)
    src = gws_presence_frames_plan_path(id: item, frame_id: frame_id)

    tag.turbo_frame(id: frame_id, class: "presence-plan", 'data-id': item.id, 'data-src': src) do
      link_to edit_gws_presence_frames_plan_path(frame_id: frame_id, id: item) do
        tag.span { user_presence.plan } +
          md_icons.filled("mode_edit", tag: :i, class: "editicon", style: "font-size: inherit").html_safe
      end
    end
  end

  def render_edit_presence_memo(item)
    frame_id = "presence-memo-#{SecureRandom.uuid}"
    user_presence = item.user_presence(@cur_site)
    src = gws_presence_frames_memo_path(id: item, frame_id: frame_id)

    tag.turbo_frame(id: frame_id, class: "presence-memo", 'data-id': item.id, 'data-src': src) do
      link_to edit_gws_presence_frames_memo_path(frame_id: frame_id, id: item) do
        tag.span { user_presence.memo } +
          md_icons.filled("mode_edit", tag: :i, class: "editicon", style: "font-size: inherit").html_safe
      end
    end
  end
end
