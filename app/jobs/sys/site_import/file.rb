module Sys::SiteImport::File
  extend ActiveSupport::Concern

  def import_ss_files
    @ss_files_map = {}

    read_json("ss_files").each do |data|
      id   = data.delete('_id')
      data = convert_data(data)
      data['original_id'] = @ss_files_map[data['original_id']] if data.key?('original_id')

      item = dummy_ss_file
      data.each { |k, v| item[k] = v }

      path = "#{@import_dir}/#{item[:export_path]}"
      next unless File.file?(path)

      def item.save_thumbs; end
      item[:export_path] = nil

      if item.save
        @ss_files_map[id] = item.id
        FileUtils.mkdir_p(File.dirname(item.path))
        FileUtils.cp(path, item.path) # FileUtils.mv
      else
        @task.log "[#{item.class}##{item.id}] " + item.errors.full_messages.join(' ')
      end
    end
  end

  def dummy_ss_file
    file = Fs::UploadedFile.new("ss_export")
    file.original_filename = 'dummy'

    item = SS::File.new(model: 'ss/dummy')
    item.in_file = file
    item.save

    item.in_file = nil
    item
  end
end
