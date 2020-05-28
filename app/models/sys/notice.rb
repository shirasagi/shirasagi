class Sys::Notice
  include SS::Document
  include SS::Reference::User
  include Sys::Addon::Body
  include SS::Addon::Release
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
  field :name, type: String
  field :notice_severity, type: String, default: NOTICE_SEVERITY_NORMAL
  field :notice_target, type: Array, default: []

  permit_params :name, :notice_severity, notice_target: []

  validates :name, presence: true, length: { maximum: 80 }

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
    return if target.blank?
    I18n.t("cms.options.notice_target.#{target}")
  end
end
