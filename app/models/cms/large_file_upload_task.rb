class Cms::LargeFileUploadTask
  include SS::Model::Task

  embeds_ids :files, class_name: "Cms::File"
  permit_params file_ids: []

  def execute(file_ids, cur_site_id)
    create_files(file_ids, cur_site_id)
  end

  private

  def create_files(files, cur_site_id)
    cur_site = Cms::Site.find(cur_site_id)

    JSON.parse(files).each do |filename, id|
      tmp_path = "#{tmp_file_path}/#{filename}"
      tmp_file = Cms::File.create_empty!(filename: filename, site_id: cur_site_id) do |file|
        ::FileUtils.copy(tmp_path, file.path)
      end

      item = Cms::File.find(id)
      ::FileUtils.copy(tmp_file.path, item.path)
      item.size = tmp_file.size
      item.save!

      File.delete(tmp_path)
      tmp_file.destroy
    end
  end

  def tmp_file_path
    "#{SS::File.root}/ss_tasks/#{self.id.to_s.chars.join("/")}"
  end
end
