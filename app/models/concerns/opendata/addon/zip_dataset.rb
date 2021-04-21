module Opendata::Addon::ZipDataset
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    after_save :compression_dataset
    after_destroy :remove_dataset_zip
  end

  def zip_path
    "#{Rails.root}/private/opendata/datasets/#{id.to_s.split("").join("/")}/_/opendata-datasets-#{id}.zip"
  end

  def zip_exists?
    File.exist?(zip_path)
  end

  def zip_size
    zip_exists? ? ::File.size(zip_path) : 0
  end

  def compression_dataset
    ::FileUtils.rm_rf(zip_path) if zip_exists?
    ::FileUtils.mkdir_p(::File.dirname(zip_path))
    return if resources.blank?

    begin
      Timeout.timeout(60) do
        files = []
        resources.each do |resource|
          if resource.source_url.present?
            name = "#{resource.name.gsub(/[#{Regexp.escape('¥/:*?\"<>|.')}]/, "_")}-#{resource.id}.txt"
            file = Tempfile.open(name)
            file.puts(resource.source_url)
            file.rewind
            files << [name, file]
          else
            name = resource.filename.split(".").join("-#{resource.id}.").to_s
            files << [name, resource.file]
          end
        end

        Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
          files.each do |name, file|
            zip.add(name.encode('cp932', invalid: :replace, undef: :replace), file.path)
          end
        end
      end
    rescue Timeout::Error => e
      message = "compression time out\n" + resources.map(&:full_url).join("\n")
      name = "resource-#{uuid}.txt"

      file = Tempfile.open(name)
      file.puts(message)
      file.rewind

      Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
        zip.add(name, file.path)
      end
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def remove_dataset_zip
    ::FileUtils.rm_rf(zip_path) if zip_exists?
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
