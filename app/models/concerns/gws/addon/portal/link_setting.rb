module Gws::Addon::Portal::LinkSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :portal_link_state, type: String, default: "show"
    permit_params :portal_link_state
    validates :portal_link_state, inclusion: { in: %w(show hide), allow_blank: true }
  end

  def portal_link_state_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def show_portal_link?
    portal_link_state.blank? || portal_link_state == "show"
  end
end
