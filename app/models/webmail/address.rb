class Webmail::Address
  include SS::Model::Address
  include SS::Reference::User
  include SS::UserPermission
  include Gws::Export

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
  end

  def address_group_options
    Webmail::AddressGroup.user(@cur_user).map do |item|
      [item.name, item.id]
    end
  end

  private

  def export_fields
    %w(id name kana company title tel email memo address_group_id)
  end

  def export_convert_item(item, data)
    data[8] = item.address_group.name if item.address_group
    data
  end

  def import_convert_data(data)
    if data[:address_group_id].present?
      group = Webmail::AddressGroup.user(@cur_user).where(name: data[:address_group_id]).first
      data[:address_group_id] = group ? group.id : nil
    end
    data
  end

  def import_find_item(data)
    self.class.user(@cur_user).where(id: data[:id]).first
  end
end
