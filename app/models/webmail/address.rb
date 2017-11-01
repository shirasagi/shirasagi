class Webmail::Address
  include SS::Model::Address
  include SS::Reference::User
  include SS::UserPermission
  include Webmail::AddressExport

  store_in collection: :webmail_addresses

  belongs_to :address_group, class_name: "Webmail::AddressGroup"

  permit_params :address_group_id

  class << self
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      if params[:address_group_id].present?
        criteria = criteria.where(address_group_id: params[:address_group_id])
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :kana, :company, :title, :tel, :email, :memo
      end

      criteria
    end

    def to_autocomplete_hash
      criteria.where(:name.exists => true, :email.exists => true).map { |item| [item.email_address, item.email] }.to_h
    end
  end

  def address_group_options
    Webmail::AddressGroup.user(@cur_user).map do |item|
      [item.name, item.id]
    end
  end
end
