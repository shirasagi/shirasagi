class Sys::SiteExport::Zip
  extend ActiveSupport::Concern

  attr_accessor :output_dir, :site_dir

  def initialize(path)
    @path = path
  end

  def compress
    Zip::Archive.open(@path, Zip::CREATE) do |zip|
      add_json(zip)
      add_private_files(zip)
      add_public_files(zip)
    end
  end

  def add_json(zip)
    Dir.glob("#{@output_dir}/*.json").each do |file|
      zip.add_file(file)
    end
  end

  def add_private_files(zip)
    require "find"
    Find.find("#{@output_dir}/files") do |path|
      entry = path.sub(/.*\/(files\/?)/, '\\1')
      if File.directory?(path)
        zip.add_dir(entry)
      else
        zip.add_file(entry, path)
      end
    end
  end

  def add_public_files(zip)
    require "find"
    Find.find(@site_dir) do |path|
      entry = path.sub(/^#{@site_dir}/, 'public')
      if File.directory?(path)
        zip.add_dir(entry)
      else
        zip.add_file(entry, path)
      end
    end
  end
end
