module Gws::Addon::Presence::DelegatorSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :presence_editable_group_state, type: String, default: "disabled"
    embeds_ids :presence_editable_titles, class_name: 'Gws::UserTitle'
    permit_params :presence_editable_group_state, presence_editable_title_ids: []
  end

  def presence_editable_group_state_options
    [
      [I18n.t("ss.options.state.enabled"), "enabled"],
      [I18n.t("ss.options.state.disabled"), "disabled"],
    ]
  end

  def presence_editable_group?
    presence_editable_group_state == "enabled"
  end
end
