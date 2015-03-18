module SS::User::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Role
  include Sys::Reference::Role
  include Ldap::Addon::User

  attr_accessor :in_password

  TYPE_SNS = "sns".freeze
  TYPE_LDAP = "ldap".freeze

  included do
    store_in collection: "ss_users"
    index({ email: 1 }, { sparse: true, unique: true })
    index({ "accounts.uid" => 1, "accounts.group_id" => 1 }, { sparse: true, unique: true })

    seqid :id
    field :name, type: String
    field :email, type: String, metadata: { form: :email }
    field :password, type: String
    field :type, type: String
    field :last_loggedin, type: DateTime

    embeds_ids :groups, class_name: "SS::Group"
    embeds_many :accounts, class_name: "SS::User::Model::Account"

    permit_params :name, :email, :password, :type, group_ids: []
    permit_params :in_password

    validates :name, presence: true, length: { maximum: 40 }
    validates :email, email: true, length: { maximum: 80 }
    validates :email, uniqueness: true, if: ->{ email.present? }
    validates :email, presence: true, if: ->{ accounts.blank? }
    validates :password, presence: true, if: ->{ ldap_dn.blank? }
    validate :validate_type
    # validates "accounts.uid", uniqueness: { scope: "accounts.group_id" }, if: ->{ accounts.present? }
    # validates :accounts.uid, uniqueness: { scope: :accounts.group_id }, if: ->{ accounts.present? }

    before_validation :encrypt_password, if: ->{ in_password.present? }

    before_save :remove_accounts, if: -> { accounts.blank? }
  end

  module ClassMethods
    public
      def authenticate(group, id, password)
        if id.include?("@")
          user = find_user_by_email(id)
        else
          user = find_user_by_uid(group, id)
        end
        return nil unless user

        if group.present? && user.ldap_dn.present?
          user.ldap_authenticate(group, password) ? user : nil
        elsif user.password.present?
          user.password == SS::Crypt.crypt(password) ? user : nil
        else
          nil
        end
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

    private
      def find_user_by_email(email)
        self.where(email: email).first
      end

      def find_user_by_uid(group, uid)
        return nil if group.blank?
        self.where("accounts.uid" => uid, "accounts.group_id" => group.id).first
      end
  end

  public
    def encrypt_password
      self.password = SS::Crypt.crypt(in_password)
    end

    # detail, descriptive name
    def long_name
      "#{name}"
    end

    def uid_of(group)
      found = accounts.select do |account|
        account.group_id == group.id
      end.first
      found.try(:uid)
    end

  private
    def validate_type
      errors.add :type, :invalid unless type.blank? || type == TYPE_SNS || type == TYPE_LDAP
    end

    def remove_accounts
      remove_attribute(:accounts) if accounts.blank?
    end
end
