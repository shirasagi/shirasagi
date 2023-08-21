class Gws::Share::FileUploader
  include SS::Document
  include Gws::Addon::Share::Category
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission

  attr_accessor :cur_site, :cur_user, :folder_id, :memo, :file_ids

  permit_params :memo, file_ids: []

  validates :file_ids, presence: true

  def save_files
    return false unless valid?

    items = []
    file_ids.select(&:numeric?).each do |file_id|
      item = Gws::Share::File.unscoped.where(id: file_id).first
      next if item.blank?

      item.model = 'share/file'
      item.cur_site = @cur_site if @cur_site
      item.cur_user = @cur_user if @cur_user
      item.folder_id = @folder_id if @folder_id
      item.category_ids = category_ids if category_ids.present?
      item.user_ids = [ @cur_user.id ] if @cur_user
      item.memo = memo

      item.readable_setting_range = readable_setting_range
      item.readable_group_ids = readable_group_ids
      item.readable_member_ids = readable_member_ids
      item.readable_custom_group_ids = readable_custom_group_ids

      item.permission_level = permission_level
      item.group_ids = group_ids
      item.user_ids = user_ids
      item.custom_group_ids = custom_group_ids

      if item.invalid?(%i[update change_model])
        SS::Model.copy_errors(item, self)
        next
      end

      items << item
    end
    return false if errors.present?

    items.all? do |item|
      result = item.save
      SS::Model.copy_errors(item, self) unless result
      result
    end
  end
end
