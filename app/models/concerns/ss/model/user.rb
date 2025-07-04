module SS::Model::User
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Fields::Normalizer
  include SS::Password
  include SS::Reference::UserExpiration
  include SS::UserImportValidator
  include SS::Addon::LocaleSetting
  include SS::Addon::Ldap::User
  include SS::Addon::MFA::UserSetting
  include SS::Addon::SSO::User
  include SS::Liquidization

  TYPE_SNS = "sns".freeze
  TYPE_LDAP = "ldap".freeze
  TYPE_SSO = "sso".freeze
  TYPES = [ TYPE_SNS, TYPE_LDAP, TYPE_SSO ].freeze

  # uidの制限をメールアドレスの"@"の左側（dot-atom-text）の仕様（RFC5322）に近づける
  # 具体的にいうと、ALPHA | DIGIT | "-" | "-" が利用でき、"." は一度だけ利用できる
  # => "." は複数回利用できるように改修
  UID_MATCHER = /^[\w\-_\.]+?$/

  included do
    attr_accessor :cur_site, :cur_user

    store_in collection: "ss_users"
    index({ email: 1 }, { sparse: true, unique: true })
    index({ uid: 1 }, { sparse: true, unique: true })
    index({ organization_uid: 1, organization_id: 1 }, { sparse: true })

    # Create indexes each site_ids.
    # > db.ss_users.ensureIndex({ "title_orders.1": -1, organization_uid: 1, uid: 1 });
    #
    # index({ "title_orders.#{site_id}" => -1, organization_uid: 1, uid: 1  })

    cattr_reader(:group_class) { SS::Group }

    seqid :id
    field :name, type: String
    field :kana, type: String
    field :uid, type: String
    field :email, type: String
    field :tel, type: String
    field :tel_ext, type: String
    field :type, type: String
    field :last_loggedin, type: DateTime
    field :account_start_date, type: DateTime
    field :account_expiration_date, type: DateTime
    field :remark, type: String
    field :organization_uid, type: String

    # Session Lifetime in seconds
    field :session_lifetime, type: Integer

    # 利用制限
    field :restriction, type: String

    # 利用停止
    field :lock_state, type: String

    # 削除ロック
    field :deletion_lock_state, type: String, default: "unlocked"

    belongs_to :organization, class_name: "SS::Group"
    belongs_to :switch_user, class_name: "SS::User"

    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :kana, :uid, :email, :tel, :tel_ext, :type, :remark, group_ids: []
    permit_params :account_start_date, :account_expiration_date, :session_lifetime
    permit_params :restriction, :lock_state, :deletion_lock_state
    permit_params :organization_id, :organization_uid, :switch_user_id

    validates :name, presence: true, length: { maximum: 40 }
    validates :kana, length: { maximum: 40 }
    # メールアドレスの"@"の左側（local-part）の最大長は64文字とするのがデファクトっぽい
    # 厳密にいうと、64文字という制限は存在せず、メールアドレス全体で254文字を超えてはいけないという制限があるのみ
    # https://stackoverflow.com/questions/386294/what-is-the-maximum-length-of-a-valid-email-address
    validates :uid, length: { maximum: 64 }
    validates :uid, uniqueness: true, if: ->{ uid.present? }
    validates :email, email: true, length: { maximum: 80 }
    validates :email, uniqueness: true, if: ->{ email.present? }
    validates :email, presence: true, if: ->{ uid.blank? && organization_uid.blank? }
    validates :type, inclusion: { in: TYPES, allow_blank: true }
    validates :last_loggedin, datetime: true
    validates :account_start_date, datetime: true
    validates :account_expiration_date, datetime: true
    validates :organization_id, presence: true, if: ->{ organization_uid.present? }
    validates :organization_uid, uniqueness: { scope: :organization_id }, if: ->{ organization_uid.present? }
    validate :validate_uid
    validate :validate_account_expiration_date

    after_save :save_group_history, if: -> { group_ids_changed? || group_ids_previously_changed? }
    before_destroy :validate_cur_user, if: ->{ cur_user.present? }

    default_scope -> {
      order_by uid: 1, email: 1
    }
    scope :uid_or_email, ->(id) { self.where("$or" => [{ email: id }, { uid: id }]) }
    scope :and_enabled, ->(now = Time.zone.now) do
      self.and(
        { "$or" => [ { "account_start_date" => nil }, { "account_start_date" => { "$lte" => now } } ] },
        { "$or" => [ { "account_expiration_date" => nil }, { "account_expiration_date" => { "$gt" => now } } ] })
    end
    scope :and_unlocked, -> do
      self.and('$or' => [{ lock_state: 'unlocked' }, { :lock_state.exists => false }])
    end

    liquidize do
      export :name
      export :kana
      export :uid
      export :email
      export :tel
      export :tel_ext
      export :organization_uid
      export :lang
    end
  end

  module ClassMethods
    def flex_find(keyword)
      if keyword.numeric?
        cond = { id: keyword }
      elsif keyword.include?('@')
        cond = { email: keyword }
      else
        cond = { uid: keyword }
      end
      self.where(cond).first
    end

    def auth_methods
      @auth_methods ||= [ :ldap_authenticate, :dbpasswd_authenticate ]
    end

    def authenticate(id, password)
      return nil if id.blank? || password.blank?

      users = uid_or_email(id)
      return nil if users.size != 1

      user = users.first
      return nil unless user

      auth_methods.each do |method|
        return user if user.send(method, password)
      end
      nil
    end

    def site_authenticate(site, id, password)
      return nil if id.blank? || password.blank?

      users = self.where(
        :organization_id.in => site.root_groups.map(&:id),
        '$or' => [{ uid: id }, { email: id }, { organization_uid: id }]
      )
      return nil if users.size != 1

      user = users.first
      auth_methods.each do |method|
        return user if user.send(method, password, site: site)
      end
      nil
    end

    def organization_authenticate(organization, id, password)
      return nil if id.blank? || password.blank?

      users = self.where(
        organization_id: organization.id,
        '$or' => [{ uid: id }, { email: id }, { organization_uid: id }]
      )
      return nil if users.size != 1

      user = users.first
      auth_methods.each do |method|
        return user if user.send(method, password, organization: organization)
      end
      nil
    end

    SEARCH_HANDLERS = %i[search_name search_title_ids search_occupation_ids search_keyword].freeze
    SEARCH_FIELDS = %i[name kana uid organization_uid email tel tel_ext remark].freeze

    def search(params)
      criteria = all
      return criteria if params.blank?

      SEARCH_HANDLERS.each do |handler|
        criteria = criteria.send(handler, params)
      end
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      cur_site = params[:cur_site]
      if self.name == 'Gws::User' && cur_site
        criteria = Gws::UserFormData.site(cur_site)
        criteria = criteria.keyword_in(params[:keyword], 'column_values.text_index')
        user_ids = criteria.pluck(:user_id)
      end

      if user_ids.blank?
        return all.keyword_in(params[:keyword], *SEARCH_FIELDS)
      end

      # before using `unscope`, we must duplicate current criteria because current contexts are all gone in `unscope`
      base_criteria = all.dup

      selector = all.unscoped.keyword_in(params[:keyword], *SEARCH_FIELDS).selector
      base_criteria.where('$or' => [ selector, { :id.in => user_ids } ])
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.search_text(params[:name])
    end

    def search_title_ids(params)
      return all if params.blank? || params[:title_ids].blank?
      all.where(title_ids: params[:title_ids].to_i)
    end

    def search_occupation_ids(params)
      return all if params.blank? || params[:occupation_ids].blank?
      all.where(occupation_ids: params[:occupation_ids].to_i)
    end

    def type_options
      TYPES.map { |type| [ I18n.t("ss.options.user_type.#{type}"), type ] }
    end

    def labels
      %w(uid email organization_uid organization_id).index_with { |key| t(key) }
    end
  end

  def email_address
    %(#{name.delete(%('"))} <#{email}>)
  end

  # detail, descriptive name
  def long_name
    uid = self.uid
    uid ||= email.split("@")[0] if email.present?
    if uid.present?
      "#{name} (#{uid})"
    else
      name.to_s
    end
  end

  def tel_label
    str = ""
    str += "TEL:#{tel}" if tel.present?
    str += "(#{t(:tel_ext_short)}:#{tel_ext})" if tel_ext.present?
    str
  end

  def type_options
    self.class.type_options
  end

  def type_sns?
    self.type == TYPE_SNS || self.type.blank?
  end

  def type_ldap?
    self.type == TYPE_LDAP
  end

  def type_sso?
    self.type == TYPE_SSO
  end

  def enabled?
    now = Time.zone.now
    return false if account_start_date.present? && account_start_date > now
    return false if account_expiration_date.present? && account_expiration_date <= now
    true
  end

  def disabled?
    !enabled?
  end

  def deletion_locked?
    deletion_lock_state == 'locked'
  end

  def deletion_unlocked?
    deletion_lock_state == 'unlocked'
  end

  def locked?
    lock_state == 'locked'
  end

  def unlocked?
    !locked?
  end

  def lock
    update(lock_state: 'locked')
  end

  def unlock
    update(lock_state: 'unlocked')
  end

  def root_groups
    groups.active.map(&:root).uniq
  end

  def session_lifetime_options
    [5, 15, 30, 60].map do |min|
      [I18n.t("ss.options.session_lifetime.#{min}min"), min * 60]
    end
  end

  def restriction_options
    %w(none api_only).map do |v|
      [ I18n.t("ss.options.restriction.#{v}"), v ]
    end
  end

  def lock_state_options
    %w(unlocked locked).map do |v|
      [ I18n.t("ss.options.user_lock_state.#{v}"), v ]
    end
  end

  def deletion_lock_state_options
    %w(unlocked locked).map do |v|
      [ I18n.t("ss.options.user_deletion_lock_state.#{v}"), v ]
    end
  end

  def restricted_api_only?
    restriction == 'api_only'
  end

  def organization_id_options(sites = [])
    list = [organization]
    sites.each do |site|
      list << site if site.is_a?(Gws::Group)
    end
    list.compact.uniq(&:id).map { |c| [c.name, c.id] }
  end

  def try_switch_user(site = nil)
    return nil unless switch_user
    return nil unless switch_user.enabled?
    switch_user
  end

  def logged_in
    if SS.config.gws.disable.blank?
      gws_user.presence_logged_in
    end
  end

  def logged_out
    if SS.config.gws.disable.blank?
      gws_user.presence_logged_out
    end
  end

  # Cast
  def cms_user
    return self if is_a?(Cms::User)
    @cms_user ||= is_a?(Cms::User) ? self : Cms::User.find(id)
  end

  def gws_user
    return self if is_a?(Gws::User)
    @gws_user ||= is_a?(Gws::User) ? self : Gws::User.find(id)
  end

  def ss_user
    return self if is_a?(SS::User)
    @sys_user ||= is_a?(SS::User) ? self : SS::User.find(id)
  end
  alias sys_user ss_user

  def webmail_user
    @webmail_user ||= begin
      if is_a?(Webmail::User)
        self
      else
        user = Webmail::User.find(id)
        user.decrypted_password = decrypted_password
        user
      end
    end
  end

  private

  def dbpasswd_authenticate(in_passwd, **_options)
    return false if !type_sns? || password.blank?
    password == SS::Crypto.crypt(in_passwd)
  end

  def validate_uid
    return if uid.blank? || UID_MATCHER.match?(uid)
    errors.add :uid, :invalid
  end

  def validate_cur_user
    if id == cur_user.id
      errors.add :base, :self_user
      return false
    else
      return true
    end
  end

  def validate_account_expiration_date
    return if account_start_date.blank? || account_expiration_date.blank?
    if account_start_date >= account_expiration_date
      errors.add :account_expiration_date, :greater_than, count: t(:account_start_date)
    end
  end

  def save_group_history
    group_ids_changes = changes['group_ids'].presence || previous_changes['group_ids']
    item = SS::UserGroupHistory.new(
      cur_site: @cur_site,
      user_id: id,
      group_ids: group_ids,
      inc_group_ids: (group_ids_changes[1].to_a - group_ids_changes[0].to_a),
      dec_group_ids: (group_ids_changes[0].to_a - group_ids_changes[1].to_a)
    )
    item.save
  end
end
