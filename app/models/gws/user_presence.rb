class Gws::UserPresence
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::GroupPermission

  set_permission_name 'gws_user_presences'

  attr_accessor :presence_state, :presence_plan, :presence_memo

  seqid :id
  field :state, type: String
  field :plan, type: String
  field :memo, type: String
  field :sync_available_state, type: String, default: "disabled"
  field :sync_unavailable_state, type: String, default: "disabled"
  permit_params :state, :plan, :memo

  validates :state, inclusion: { in: I18n.t("gws/presence.options.presence_state").keys.map(&:to_s), allow_blank: true }
  validates :plan, length: { maximum: 400 }
  validates :memo, length: { maximum: 400 }

  before_validation :set_presence_attributes

  def set_presence_attributes
    self.state = presence_state if presence_state
    self.plan = presence_plan if presence_plan
    self.memo = presence_memo if presence_memo
  end

  def state_options
    [
      [I18n.t("gws/presence.options.presence_state.available"), "available"],
      [I18n.t("gws/presence.options.presence_state.unavailable"), "unavailable"],
      [I18n.t("gws/presence.options.presence_state.leave"), "leave"],
      [I18n.t("gws/presence.options.presence_state.dayoff"), "dayoff"],
      [I18n.t("gws/presence.options.presence_state.none"), ""]
    ]
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

  def sync_available_enabled?
    sync_available_state == "enabled"
  end

  def sync_unavailable_enabled?
    sync_unavailable_state == "enabled"
  end
end
