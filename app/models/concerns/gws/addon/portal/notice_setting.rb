module Gws::Addon::Portal::NoticeSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :portal_notice_state, type: String, default: "show"
    field :portal_notice_browsed_state, type: String
    field :portal_notice_severity, type: String
    permit_params :portal_notice_state, :portal_notice_browsed_state, :portal_notice_severity

    before_validation :set_default_notice_setting

    validates :portal_notice_state, inclusion: { in: %w(show hide), allow_blank: true }
    validates :portal_notice_browsed_state, inclusion: { in: %w(unread read both), allow_blank: true }
    validates :portal_notice_severity, inclusion: { in: %w(all high), allow_blank: true }
  end

  def portal_notice_state_options
    %w(show hide).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def portal_notice_severity_options
    %w(all high).map do |v|
      [ I18n.t("gws/notice.options.severity.#{v}"), v ]
    end
  end

  def portal_notice_browsed_state_options
    %w(both unread read).map do |v|
      [ I18n.t("gws/board.options.browsed_state.#{v}"), v ]
    end
  end

  def show_portal_notice?
    portal_notice_state.blank? || portal_notice_state == "show"
  end

  private

  def set_default_notice_setting
    site = cur_site || site
    return unless site

    if portal_notice_severity.blank?
      self.portal_notice_severity = site.notice_severity
    end
    if portal_notice_browsed_state.blank?
      self.portal_notice_browsed_state = site.notice_browsed_state
    end
  end
end
