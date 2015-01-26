module SS::User::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Role
  include Sys::Reference::Role

  attr_accessor :in_password

  included do
    store_in collection: "ss_users"
    index({ email: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :email, type: String, metadata: { form: :email }
    field :password, type: String
    field :type, type: String
    field :last_loggedin, type: DateTime

    embeds_ids :groups, class_name: "SS::Group"

    permit_params :name, :email, :password, :in_password, :type, group_ids: []

    validates :name, presence: true, length: { maximum: 40 }
    validates :email, uniqueness: true, presence: true, email: true, length: { maximum: 80 }
    validates :password, presence: true

    before_validation :encrypt_password, if: ->{ in_password.present? }

    public
      def type_options
        [%w(SNSユーザー sns), %w(LDAPユーザー ldap)]
      end
  end

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
  end
end
