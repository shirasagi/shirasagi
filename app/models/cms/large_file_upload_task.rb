class Cms::LargeFileUploadTask
  include SS::Model::Task

  field :acceptable_files, type: Array
  field :excluded_files, type: SS::Extensions::Words

  def prepare!(filenames)
    if filenames.blank?
      update!(acceptable_files: SS::EMPTY_ARRAY, excluded_files: SS::EMPTY_ARRAY)
      clear_parts
      return
    end

    acceptable_files = []
    excluded_files = []
    filenames.each do |filename|
      filename = filename.to_s
      extname = ::File.extname(filename)
      if SS::MaxFileSize.find_item(extname)
        acceptable_files << { "_id" => BSON::ObjectId.new, "filename" => filename, "last_part_no" => 0 }
      else
        excluded_files << filename
      end
    end

    update!(acceptable_files: acceptable_files, excluded_files: excluded_files)
    clear_parts
  end

  def append_blob!(filename, io, part_no)
    raise if acceptable_files.blank?

    filename = filename.to_s
    acceptable_file = acceptable_files.find { _1["filename"] == filename }
    raise unless acceptable_file
    return if part_no != acceptable_file["last_part_no"]

    part_filepath = "#{base_dir}/part_#{acceptable_file["_id"]}"
    Retriable.retriable do
      FileUtils.mkdir_p(base_dir)
      ::File.open(part_filepath, "ab") do |f|
        IO.copy_stream(io, f)
      end
    end

    acceptable_file["last_part_no"] = acceptable_file["last_part_no"] + 1
    self.acceptable_files = acceptable_files.dup
    save!
  end

  def execute!(cur_user)
    acceptable_files.each do |acceptable_file|
      part_filepath = "#{base_dir}/part_#{acceptable_file["_id"]}"

      next unless ::File.exist?(part_filepath)
      next if ::File.empty?(part_filepath)

      filename = ::File.basename(acceptable_file["filename"])

      Retriable.retriable do
        Cms::File.create_empty!(
          filename: filename, site_id: site_id, user_id: cur_user.id, group_ids: cur_user.group_ids) do |file|
          FileUtils.copy(part_filepath, file.path)
        end
      end
    end
  ensure
    clear_parts
  end

  private

  def clear_parts
    Retriable.retriable do
      FileUtils.mkdir_p(base_dir)
      Dir.glob("#{base_dir}/part_*").each { |filepath| FileUtils.rm_f(filepath) }
    end
  end
end
