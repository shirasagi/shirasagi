module SS::Model::User
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Fields::Normalizer
  include Ldap::Addon::User

  attr_accessor :cur_user, :in_password

  TYPE_SNS = "sns".freeze
  TYPE_LDAP = "ldap".freeze

  LOGIN_ROLE_DBPASSWD = "dbpasswd".freeze
  LOGIN_ROLE_LDAP = "ldap".freeze

  included do
    store_in collection: "ss_users"
    index({ email: 1 }, { sparse: true, unique: true })
    index({ uid: 1 }, { sparse: true, unique: true })

    cattr_reader(:group_class) { SS::Group }

    seqid :id
    field :name, type: String
    field :uid, type: String
    field :email, type: String
    field :password, type: String
    field :tel, type: String
    field :type, type: String
    field :login_roles, type: Array, default: [LOGIN_ROLE_DBPASSWD]
    field :last_loggedin, type: DateTime

    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :uid, :email, :password, :tel, :type, :login_roles, group_ids: []
    permit_params :in_password

    validates :name, presence: true, length: { maximum: 40 }
    validates :uid, length: { maximum: 40 }
    validates :uid, uniqueness: true, if: ->{ uid.present? }
    validates :email, email: true, length: { maximum: 80 }
    validates :email, uniqueness: true, if: ->{ email.present? }
    validates :email, presence: true, if: ->{ uid.blank? }
    validates :password, presence: true, if: ->{ ldap_dn.blank? }
    validate :validate_type
    validate :validate_uid

    before_validation :encrypt_password, if: ->{ in_password.present? }
    before_destroy :validate_cur_user, if: ->{ cur_user.present? }

    scope :uid_or_email, ->(id) { self.or({email: id}, {uid: id}) }
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
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :email
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
      "#{name}(#{uid})"
    else
      "#{name}"
    end
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
end
