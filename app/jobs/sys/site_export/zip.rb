class Sys::SiteExport::Zip
  extend ActiveSupport::Concern

  attr_accessor :output_dir, :site_dir, :exclude_public_files

  def initialize(path, opts = {})
    @path = path
    @exclude_public_files = opts[:exclude_public_files] || []
  end

  def compress
    Zip::File.open(@path, Zip::File::CREATE) do |zip|
      add_json(zip)
      add_private_files(zip)
      add_public_files(zip) if FileTest.directory?(@site_dir)
    end
  end

  def add_json(zip)
    Dir.glob("#{@output_dir}/*.json").each do |file|
      name = ::File.basename(file)
      name = ::Fs.zip_safe_name(name)
      zip.add(name, file)
    end
  end

  def add_private_files(zip)
    require "find"
    Find.find("#{@output_dir}/files") do |path|
      entry = path.sub(/.*\/(files\/?)/, '\\1')
      entry = ::Fs.zip_safe_path(entry)
      if File.directory?(path)
        zip.mkdir(entry)
      else
        zip.add(entry, path)
      end
    end
  end

  def site_fs_path
    @_site_fs_path ||= begin
      site_dir ? ::File.join(site_dir, "fs/") : ""
    end
  end

  def add_public_files(zip)
    require "find"
    Find.find(@site_dir) do |path|
      next if path =~ /^#{site_fs_path}/
      next if @exclude_public_files.include?(path)

      entry = path.sub(/^#{@site_dir}/, 'public')
      entry = ::Fs.zip_safe_path(entry)
      if File.directory?(path)
        zip.mkdir(entry)
      else
        zip.add(entry, path)
      end
    end
  end
end
