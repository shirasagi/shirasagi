module Gws::Addon::Portal::NoticeSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :portal_notice_state, type: String, default: "show"
    field :portal_notice_browsed_state, type: String, default: ->{ SS.config.gws.notice['portal_browsed_state'] || 'unread' }
    permit_params :portal_notice_state, :portal_notice_browsed_state

    validates :portal_notice_state, inclusion: { in: %w(show hide), allow_blank: true }
    validates :portal_notice_browsed_state, inclusion: { in: %w(unread read both), allow_blank: true }
  end

  def portal_notice_state_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def portal_notice_browsed_state_options
    %w(unread read both).map do |v|
      [ I18n.t("gws/board.options.browsed_state.#{v}"), v ]
    end
  end

  def show_portal_notice?
    portal_notice_state.blank? || portal_notice_state == "show"
  end
end
