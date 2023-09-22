class SS::Migration20190301000001
  include SS::Migration::Base

  depends_on "20190204000000"

  def change
    all_ids = Sys::Setting.all.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Sys::Setting.all.in(id: ids).each do |setting|
        setting.file_ids.each_slice(20) do |file_ids|
          SS::LinkFile.unscoped.all.in(id: file_ids).to_a.each do |file|
            file.model = "ss/link_file"
            file.owner_item = setting
            file.state = "public"
            file.without_record_timestamps { file.save }
          end
        end
      end
    end
  end
end
