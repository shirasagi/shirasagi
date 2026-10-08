class Cms::LargeFileUploadTask
  include SS::Model::Task

  field :acceptable_files, type: Array

  class << self
    def max_file_size
      @max_file_size ||= 2 * 1_024 * 1_024 * 1_024
    end

    if Rails.env.test?
      # rubocop:disable Style/TrivialAccessors
      def max_file_size=(value)
        @max_file_size = value
      end
      # rubocop:enable Style/TrivialAccessors
    end
  end

  PrepareParam = Data.define(:file_id, :filename, :size)

  def prepare!(prepare_params)
    synchronize! do
      if prepare_params.blank?
        update!(acceptable_files: SS::EMPTY_ARRAY)
        clear_parts
        next
      end

      acceptable_files = []
      prepare_params.each do |prepare_param|
        file_id = prepare_param.file_id.to_s
        next if file_id.blank?

        filename = prepare_param.filename.to_s
        next if filename.blank?

        basename = ::File.basename(filename)
        next if basename.blank?

        next unless prepare_param.size.numeric?

        size = prepare_param.size.to_i
        next if size <= 0
        next if size > self.class.max_file_size

        extname = ::File.extname(filename)
        next unless SS::MaxFileSize.find_item(extname)

        acceptable_files << {
          "_id" => BSON::ObjectId.new, "file_id" => file_id, "filename" => filename,
          "last_part_no" => 0, "expected_size" => size
        }
      end

      update!(acceptable_files: acceptable_files)
      clear_parts
    end
  end

  def append_blob!(file_id, io, part_no)
    synchronize! do
      raise if acceptable_files.blank?

      file_id = file_id.to_s
      acceptable_file = acceptable_files.find { _1["file_id"] == file_id }
      raise unless acceptable_file
      next if part_no != acceptable_file["last_part_no"]

      part_filepath = "#{base_dir}/part_#{acceptable_file["_id"]}"
      part_size = ::File.exist?(part_filepath) ? ::File.size(part_filepath) : 0
      raise if part_size + io.size > acceptable_file["expected_size"]

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
  end

  def execute!(cur_user)
    synchronize! do
      succeeded_ids = []
      acceptable_files = self.acceptable_files.dup
      acceptable_files.each do |acceptable_file|
        part_filepath = "#{base_dir}/part_#{acceptable_file["_id"]}"
        next unless ::File.exist?(part_filepath)

        actual_size = ::File.size(part_filepath)
        next if actual_size != acceptable_file["expected_size"]

        filename = ::File.basename(acceptable_file["filename"])
        Retriable.retriable do
          Cms::File.create_empty!(
            filename: filename, site_id: site_id, user_id: cur_user.id, group_ids: cur_user.group_ids) do |file|
            FileUtils.copy(part_filepath, file.path)
          end
        end

        Retriable.retriable do
          FileUtils.rm_f(part_filepath)
        end

        succeeded_ids << acceptable_file["_id"]
      end
    ensure
      succeeded_ids.each do |id|
        acceptable_files.delete_if { _1["_id"] == id }
      end
      update!(acceptable_files: acceptable_files)
    end
  end

  private

  def synchronize!(&block)
    run_with(resolved: block, rejected: ->{ raise "unable to acquire lock" })
  end

  def clear_parts
    Retriable.retriable do
      FileUtils.mkdir_p(base_dir)
      Dir.glob("#{base_dir}/part_*").each { |filepath| FileUtils.rm_f(filepath) }
    end
  end
end
