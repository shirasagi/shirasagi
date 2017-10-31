class Webmail::Address
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission

  field :name, type: String
  field :email, type: String
  field :memo, type: String

  permit_params :name, :email, :memo

  validates :name, presence: true
  validates :email, presence: true, email: true

  default_scope -> { order_by name: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :email, :memo if params[:keyword].present?
    criteria
  }

  def email_address
    %(#{name} <#{email}>)
  end

  class << self
    def to_autocomplete_hash
      criteria.where(:name.exists => true, :email.exists => true).map { |item| [item.email_address, item.email] }.to_h
    end
  end
end
