class Webmail::AddressGroup
  include SS::Document
  include SS::Reference::User
  include SS::UserPermission

  store_in collection: :webmail_address_groups

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true, uniqueness: { scope: :user_id }

  default_scope ->{ order_by order: 1 }

  class << self
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end
  end
end
