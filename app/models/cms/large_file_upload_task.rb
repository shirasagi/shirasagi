class Cms::LargeFileUploadTask
  include SS::Model::Task

  field :acceptable_files, type: SS::Extensions::Words
  field :excluded_files, type: SS::Extensions::Words

  def prepare!(filenames)
    acceptable_files = []
    excluded_files = []

    if filenames.present?
      filenames.each do |filename|
        filename = File.basename(filename.to_s)
        extname = File.extname(filename)
        if SS::MaxFileSize.find_item(extname)
          acceptable_files << filename
        else
          excluded_files << filename
        end
      end
    end

    update!(acceptable_files: acceptable_files, excluded_files: excluded_files)

    Retriable.retriable do
      FileUtils.mkdir_p(base_dir)
      Dir.glob("#{base_dir}/part_*").each { |filepath| FileUtils.rm_f(filepath) }
    end
  end

  def append_blob!(filename, io)
    raise if acceptable_files.blank?

    index = acceptable_files.find_index(filename)
    raise unless index

    part_filepath = "#{base_dir}/part_#{index}"
    Retriable.retriable do
      FileUtils.mkdir_p(base_dir)
      ::File.open(part_filepath, "ab") do |f|
        IO.copy_stream(io, f)
      end
    end
  end

  def execute!(cur_user)
    acceptable_files.each_with_index do |filename, index|
      part_filepath = "#{base_dir}/part_#{index}"

      Retriable.retriable do
        Cms::File.create_empty!(
          filename: filename, site_id: site_id, user_id: cur_user.id, group_ids: cur_user.group_ids) do |file|
          ::FileUtils.copy(part_filepath, file.path)
        end
      end

      Retriable.retriable do
        FileUtils.rm_f(part_filepath)
      end
    end
  end
end
