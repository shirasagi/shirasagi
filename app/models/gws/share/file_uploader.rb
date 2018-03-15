class Gws::Share::FileUploader
  include SS::Document
  include Gws::Addon::Share::Category

  attr_accessor :cur_site, :cur_user, :folder_id, :readable_member_ids
  attr_accessor :file_ids
  permit_params file_ids: []

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
      item.readable_member_ids = @readable_member_ids if @readable_member_ids
      item.user_ids = [ @cur_user.id ] if @cur_user
      if item.invalid?
        errors[:base] += item.errors.full_messages
        next
      end

      items << item
    end
    return false if errors.present?

    items.each { |item| item.save }
  end
end
