class Sys::Notice
  include SS::Document
  include SS::Reference::User
  include Sys::Addon::Body
  include Sys::Permission

  set_permission_name "sys_notices", :edit

  NOTICE_SEVERITY_NORMAL = "normal".freeze
  NOTICE_SEVERITY_HIGH ="high".freeze
  NOTICE_SEVERITIES = [ NOTICE_SEVERITY_NORMAL, NOTICE_SEVERITY_HIGH ].freeze

  NOTICE_TARGET_LOGIN_VIEW = "login_view".freeze
  NOTICE_TARGET_CMS_ADMIN = "cms_admin".freeze
  NOTICE_TARGET_GROUP_WEAR = "gw_admin".freeze
  NOTICE_TARGET_WEB_MAIL = "webmail_admin".freeze
  NOTICE_TARGET_SYS_ADMIN = "sys_admin".freeze
  NOTICE_TARGETS = [
    NOTICE_TARGET_LOGIN_VIEW,
    NOTICE_TARGET_CMS_ADMIN,
    NOTICE_TARGET_GROUP_WEAR,
    NOTICE_TARGET_WEB_MAIL,
    NOTICE_TARGET_SYS_ADMIN
  ].freeze

  seqid :id
  field :state, type: String, default: "public"
  field :name, type: String
  field :released, type: DateTime
  field :notice_severity, type: String, default: NOTICE_SEVERITY_NORMAL
  field :notice_target, type: Array, default: []
  field :release_date, type: DateTime
  field :close_date, type: DateTime

  permit_params :state, :html, :name, :released, :notice_severity, notice_target: []
  permit_params :release_date, :close_date

  before_validation :set_released, if: -> { state == "public" }

  validates :state, presence: true
  validates :name, presence: true, length: { maximum: 80 }
  validates :released, datetime: true
  validates :release_date, datetime: true
  validates :close_date, datetime: true
  validate :validate_release_date

  default_scope -> {
    order_by released: -1
  }

  scope :cms_admin_notice, -> {
    where(:notice_target.in => [NOTICE_TARGET_CMS_ADMIN])
  }

  scope :sys_admin_notice, -> {
    where(:notice_target.in => [NOTICE_TARGET_SYS_ADMIN])
  }

  scope :gw_admin_notice, -> {
    where(:notice_target.in => [NOTICE_TARGET_GROUP_WEAR])
  }

  scope :webmail_admin_notice, -> {
    where(:notice_target.in => [NOTICE_TARGET_WEB_MAIL])
  }

  scope :and_show_login, -> {
    where(:notice_target.in => [NOTICE_TARGET_LOGIN_VIEW])
  }

  scope :and_public, ->(date = Time.zone.now) {
    where("$and" => [
      { "$or" => [ { state: "public" }, { state: "ready" } ]},
      { "$or" => [ { release_date: nil }, { :release_date.lte => date } ] },
      { "$or" => [ { close_date: nil }, { :close_date.gte => date } ] },
    ])
  }

  scope :target_to, ->(user) {
    where("$or" => [
      { notice_target: NOTICE_TARGET_LOGIN_VIEW },
      { "$and" => [ { notice_target: NOTICE_TARGET_CMS_ADMIN }, { :group_ids.in => user.group_ids } ] }
    ])
  }

  scope :search, ->(params = {}) {
    criteria = self.where({})
    return criteria if params.blank?

    criteria = criteria.search_text params[:name] if params[:name].present?
    criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }

  def notice_severity_options
    NOTICE_SEVERITIES.map { |v| [ I18n.t("cms.options.notice_severity.#{v}"), v ] }.to_a
  end

  def notice_target_options
    NOTICE_TARGETS.map { |v| [ I18n.t("cms.options.notice_target.#{v}"), v ] }
  end

  def disp_notice_target(target)
    I18n.t("cms.options.notice_target.#{target}")
  end

  def state_options
    [
      [I18n.t('ss.options.state.public'), 'public'],
      [I18n.t('ss.options.state.closed'), 'closed'],
    ]
  end

  private

  def set_released
    self.released ||= Time.zone.now
  end

  def validate_release_date
    return if release_date.blank?
    return if close_date.blank?

    errors.add :close_date, :greater_than, count: t(:release_date) if release_date >= close_date
  end
end
