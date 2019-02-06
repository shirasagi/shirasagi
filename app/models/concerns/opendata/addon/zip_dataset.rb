module Opendata::Addon::ZipDataset
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    after_save :compression_dataset
    after_destroy :remove_dataset_zip
  end

  def dataset
    if self.is_a?(Opendata::Dataset)
      return self
    elsif self.is_a?(Opendata::Resource)
      return self.dataset
    end
  end

  def zip_path
    "#{Rails.root}/private/opendata/datasets/#{dataset.id.to_s.split("").join("/")}/_"
  end

  def zip_exists?
    File.exist?("#{zip_path}/opendata-datasets-#{dataset.id}.zip")
  end

  def compression_dataset
    output_zip = "#{zip_path}/opendata-datasets-#{dataset.id}.zip"

    FileUtils.rm_rf(output_zip)
    FileUtils.mkdir_p(zip_path)

    return if dataset.resources.blank?

    begin
      Timeout.timeout(60) do
        files = []
        dataset.resources.each do |resource|
          if resource.source_url.present?
            name = "#{resource.name}-#{resource.id}.txt"
            file = Tempfile.open(name)
            file.puts(resource.source_url)
            file.rewind
            files << [name, file]
          else
            name = "#{resource.file.name.split(".").join("-#{resource.id}.")}"
            files << [name, resource.file]
          end
        end

        Zip::File.open(output_zip, Zip::File::CREATE) do |zip|
          files.each do |name, file|
            zip.add(name.encode('cp932', invalid: :replace, undef: :replace), file.path)
          end
        end
      end
    rescue Timeout::Error => e
      message = "compression time out\n" + dataset.resources.map(&:full_url).join("\n")
      name = "resource-#{uuid}.txt"

      file = Tempfile.open(name)
      file.puts(message)
      file.rewind

      Zip::File.open(output_zip, Zip::File::CREATE) do |zip|
        zip.add(name, file.path)
      end
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def remove_dataset_zip
    output_zip = "#{zip_path}/opendata-datasets-#{dataset.id}.zip"

    FileUtils.rm_rf(output_zip) if zip_exists?
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
