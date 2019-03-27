class Gws::SharedAddress::Address
  include SS::Model::Address
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Export

  belongs_to :address_group, class_name: "Gws::SharedAddress::Group"

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
    Gws::SharedAddress::Group.site(@cur_site).allow(:read, @cur_user, site: @cur_site).map do |item|
      [item.name, item.id]
    end
  end

  private

  def export_fields
    %w(id member_id address_group_id name kana company title tel email memo)
  end

  def export_convert_item(item, data)
    data[1] = item.member ? item.member.uid : nil
    data[2] = item.address_group ? item.address_group.name : nil
    data
  end

  def import_convert_data(data)
    if data[:member_id].present?
      member = Gws::User.site(@cur_site).where(uid: data[:member_id]).first
      data[:member_id] = member ? member.id : nil
    end
    if data[:address_group_id].present?
      group = Gws::SharedAddress::Group.site(@cur_site).where(name: data[:address_group_id]).first
      data[:address_group_id] = group ? group.id : nil
    end
    data
  end
end
