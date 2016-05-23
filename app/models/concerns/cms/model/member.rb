module Cms::Model::Member
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  attr_accessor :in_password

  OAUTH_PROVIDER_TWITTER = 'twitter'.freeze
  OAUTH_PROVIDER_FACEBOOK = 'facebook'.freeze
  OAUTH_PROVIDER_YAHOOJP = 'yahoojp'.freeze
  OAUTH_PROVIDER_GOOGLE_OAUTH2 = 'google_oauth2'.freeze
  OAUTH_PROVIDER_GITHUB = 'github'.freeze
  OAUTH_PROVIDERS = [ OAUTH_PROVIDER_TWITTER, OAUTH_PROVIDER_FACEBOOK, OAUTH_PROVIDER_YAHOOJP,
                      OAUTH_PROVIDER_GOOGLE_OAUTH2, OAUTH_PROVIDER_GITHUB ].freeze

  included do
    store_in collection: "cms_members"
    set_permission_name "cms_members", :edit

    seqid :id
    field :name, type: String
    field :email, type: String
    field :password, type: String
    field :oauth_type, type: String
    field :oauth_id, type: String
    field :oauth_token, type: String
    field :site_email, type: String
    field :last_loggedin, type: DateTime

    permit_params :name, :email, :password, :in_password

    validates :name, presence: true, length: { maximum: 40 }
    validates :email, email: true, length: { maximum: 80 }
    validates :email, uniqueness: { scope: :site_id }, presence: true, if: ->{ oauth_type.blank? }
    validates :password, presence: true, if: ->{ oauth_type.blank? }

    before_validation :encrypt_password, if: ->{ in_password.present? }
    before_save :set_site_email, if: ->{ email.present? }
  end

  module ClassMethods
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :email
      end
      criteria
    end

    def to_csv
      CSV.generate do |data|
        data << %w(id name email email_type updated created)
        criteria.each do |item|
          line = []
          line << item.id
          line << item.name
          line << item.email
          line << item.email_type
          line << item.updated.strftime("%Y/%m/%d %H:%M")
          line << item.created.strftime("%Y/%m/%d %H:%M")
          data << line
        end
      end
    end
  end

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
  end

  private
    def set_site_email
      self.site_email = "#{site_id}_#{email}"
    end
end
