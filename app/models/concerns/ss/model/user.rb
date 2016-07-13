module SS::Model::User
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Fields::Normalizer
  include SS::Reference::UserTitles
  include SS::Reference::UserExpiration
  include Ldap::Addon::User

  attr_accessor :cur_site, :cur_user, :in_password, :self_edit

  TYPE_SNS = "sns".freeze
  TYPE_LDAP = "ldap".freeze

  LOGIN_ROLE_DBPASSWD = "dbpasswd".freeze
  LOGIN_ROLE_LDAP = "ldap".freeze

  included do
    store_in collection: "ss_users"
    index({ email: 1 }, { sparse: true, unique: true })
    index({ uid: 1 }, { sparse: true, unique: true })

    # Create indexes each site_ids.
    # > db.ss_users.ensureIndex({ "title_orders.1": -1, uid: 1 });
    #
    # index({ "title_orders.#{site_id}" => -1, uid: 1  })

    cattr_reader(:group_class) { SS::Group }

    seqid :id
    field :name, type: String
    field :kana, type: String
    field :uid, type: String
    field :email, type: String
    field :password, type: String
    field :tel, type: String
    field :tel_ext, type: String
    field :type, type: String
    field :login_roles, type: Array, default: [LOGIN_ROLE_DBPASSWD]
    field :last_loggedin, type: DateTime
    field :account_start_date, type: DateTime
    field :account_expiration_date, type: DateTime
    field :remark, type: String

    # 初期パスワード警告 / nil: 無効, 1: 有効
    field :initial_password_warning, type: Integer

    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :kana, :uid, :email, :password, :tel, :tel_ext, :type, :login_roles, :remark, group_ids: []
    permit_params :in_password
    permit_params :account_start_date, :account_expiration_date, :initial_password_warning

    before_validation :encrypt_password, if: ->{ in_password.present? }

    validates :name, presence: true, length: { maximum: 40 }
    validates :kana, length: { maximum: 40 }
    validates :uid, length: { maximum: 40 }
    validates :uid, uniqueness: true, if: ->{ uid.present? }
    validates :email, email: true, length: { maximum: 80 }
    validates :email, uniqueness: true, if: ->{ email.present? }
    validates :email, presence: true, if: ->{ uid.blank? }
    validates :password, presence: true, if: ->{ ldap_dn.blank? }
    validates :last_loggedin, datetime: true
    validates :account_start_date, datetime: true
    validates :account_expiration_date, datetime: true
    validate :validate_type
    validate :validate_uid
    validate :validate_account_expiration_date
    validate :validate_initial_password, if: -> { self_edit }

    after_save :save_group_history, if: -> { @db_changes['group_ids'] }
    before_destroy :validate_cur_user, if: ->{ cur_user.present? }

    default_scope -> {
      order_by uid: 1, email: 1
    }
    scope :uid_or_email, ->(id) { self.or({email: id}, {uid: id}) }
    scope :and_enabled, ->(now = Time.zone.now) do
      self.and(
        { "$or" => [ { "account_start_date" => nil }, { "account_start_date" => { "$lte" => now } } ] },
        { "$or" => [ { "account_expiration_date" => nil }, { "account_expiration_date" => { "$gt" => now } } ] })
    end
  end

  module ClassMethods
    def flex_find(keyword)
      if keyword =~ /^\d+$/
        cond = { id: keyword }
      elsif keyword =~ /@/
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
      user = uid_or_email(id).first
      return nil unless user

      auth_methods.each do |method|
        return user if user.send(method, password)
      end
      nil
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:title_ids].present?
        criteria = criteria.where title_ids: params[:title_ids].to_i
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :kana, :uid, :email
      end
      criteria
    end

    def type_options
      [ [ t(TYPE_SNS), TYPE_SNS ], [ t(TYPE_LDAP), TYPE_LDAP ] ]
    end
  end

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
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

  def enabled?
    now = Time.zone.now
    return false if account_start_date.present? && account_start_date > now
    return false if account_expiration_date.present? && account_expiration_date <= now
    true
  end

  def initial_password_warning_options
    [
      [I18n.t('views.options.state.disabled'), ''],
      [I18n.t('views.options.state.enabled'), 1],
    ]
  end

  def root_groups
    groups.active.map(&:root).uniq
  end

  private
    def dbpasswd_authenticate(in_passwd)
      return false unless login_roles.include?(LOGIN_ROLE_DBPASSWD)
      return false if password.blank?
      password == SS::Crypt.crypt(in_passwd)
    end

    def validate_type
      errors.add :type, :invalid unless type.blank? || type == TYPE_SNS || type == TYPE_LDAP
    end

    def validate_uid
      return if uid.blank?
      errors.add :uid, :invalid if uid !~ /^[\w\-]+$/
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

    def validate_initial_password
      self.initial_password_warning = nil if password_changed?
    end

    def save_group_history
      changes = @db_changes['group_ids']
      item = SS::UserGroupHistory.new(
        cur_site: @cur_site,
        user_id: id,
        group_ids: group_ids,
        inc_group_ids: (changes[1].to_a - changes[0].to_a),
        dec_group_ids: (changes[0].to_a - changes[1].to_a)
      )
      item.save
    end
end
