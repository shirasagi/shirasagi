class Gws::UserPresence
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_user_presences'

  attr_accessor :presence_state, :presence_plan, :presence_memo

  seqid :id
  field :state, type: String, default: ""
  field :plan, type: String, default: ""
  field :memo, type: String, default: ""
  field :sync_available_state, type: String, default: "disabled"
  field :sync_unavailable_state, type: String, default: "disabled"
  field :sync_timecard_state, type: String, default: "enabled"
  permit_params :state, :plan, :memo

  validates :state, inclusion: { in: ::SS.config.gws["presence"]["state"].map(&:keys).flatten }
  validates :plan, length: { maximum: 400 }
  validates :memo, length: { maximum: 400 }

  before_validation :set_presence_attributes

  def set_presence_attributes
    self.state = presence_state if presence_state
    self.plan = presence_plan if presence_plan
    self.memo = presence_memo if presence_memo
  end

  def state_options
    @_state_options ||= ::SS.config.gws["presence"]["state"].map { |h| h.first.reverse }
  end

  def state_styles
    @_state_styles ||= ::SS.config.gws["presence"]["style"]
  end

  def state_style(state = nil)
    key = state || self.state
    state_styles[key.to_s] || "none"
  end

  def sync_available_state_options
    [
      [I18n.t('ss.options.state.disabled'), "disabled"],
      [I18n.t('ss.options.state.enabled'), "enabled"]
    ]
  end

  def sync_unavailable_state_options
    [
      [I18n.t('ss.options.state.disabled'), "disabled"],
      [I18n.t('ss.options.state.enabled'), "enabled"]
    ]
  end

  def sync_timecard_state_options
    [
      [I18n.t('ss.options.state.disabled'), "disabled"],
      [I18n.t('ss.options.state.enabled'), "enabled"]
    ]
  end

  def sync_available_enabled?
    return false if SS.config.gws.dig("presence", "sync_available", "disable")
    sync_available_state == "enabled"
  end

  def sync_unavailable_enabled?
    return false if SS.config.gws.dig("presence", "sync_available", "disable")
    sync_unavailable_state == "enabled"
  end

  def sync_timecard_enabled?
    return false if SS.config.gws.dig("presence", "sync_timecard", "disable")
    sync_timecard_state == "enabled"
  end
end
