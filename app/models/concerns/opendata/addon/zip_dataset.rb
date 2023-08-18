module Opendata::Addon::ZipDataset
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    after_save :compression_dataset
    after_destroy :remove_dataset_zip
  end

  def zip_path
    "#{Rails.root}/private/opendata/datasets/#{id.to_s.chars.join("/")}/_/opendata-datasets-#{id}.zip"
  end

  def zip_exist?
    File.exist?(zip_path)
  end

  def zip_size
    zip_exist? ? ::File.size(zip_path) : 0
  end

  def compression_dataset
    ::FileUtils.rm_rf(zip_path) if zip_exist?
    return if resources.blank?

    name_util = SS::FilenameUtils.new
    begin
      Timeout.timeout(60) do
        files = []
        resources.each do |resource|
          if resource.source_url.present?
            name = "#{resource.name.gsub(/[#{Regexp.escape('¥/:*?\"<>|.')}]/, "_")}.txt"
            file = Tempfile.open(name)
            file.puts(resource.source_url)
            file.rewind
            files << [name_util.format_duplicates(name), file]
          else
            files << [name_util.format_duplicates(resource.filename), resource.file]
          end
        end

        ::FileUtils.mkdir_p(::File.dirname(zip_path))
        Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
          files.each do |name, file|
            name = ::Fs.zip_safe_path(name)
            zip.add(name, file.path)
          end
        end
      end
    rescue Timeout::Error => e
      message = "compression time out\n" + resources.map(&:full_url).join("\n")
      name = "resource-#{uuid}.txt"

      file = Tempfile.open(name)
      file.puts(message)
      file.rewind

      ::FileUtils.mkdir_p(::File.dirname(zip_path))
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
        zip.add(name, file.path)
      end
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def remove_dataset_zip
    ::FileUtils.rm_rf(zip_path) if zip_exist?
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
