class SS::Migration20180402000000
  include SS::Migration::Base

  depends_on "20180228000000"

  def change
    folder_ids = Gws::Share::Folder.all.pluck(:id)
    folder_ids.each do |id|
      folder = Gws::Share::Folder.find(id) rescue nil
      next unless folder
      folder.update_folder_descendants_file_info
    end
  end
end
