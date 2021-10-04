class Sys::SiteExport::Zip
  extend ActiveSupport::Concern

  attr_accessor :output_dir, :site_dir, :exclude_public_files

  def initialize(path, opts = {})
    @path = path
    @exclude_public_files = opts[:exclude_public_files] || []
  end

  def compress
    save_write_zip64_support = Zip.write_zip64_support
    save_unicode_names = Zip.unicode_names
    Zip.write_zip64_support = true
    Zip.unicode_names = true
    Zip::File.open(@path, Zip::File::CREATE) do |zip|
      add_json(zip)
      add_private_files(zip)
      add_public_files(zip) if FileTest.directory?(@site_dir)
    end
  ensure
    Zip.write_zip64_support = save_write_zip64_support
    Zip.unicode_names = save_unicode_names
  end

  def add_json(zip)
    Dir.glob("#{@output_dir}/*.json").each do |file|
      name = ::File.basename(file)
      zip.add(name, file)
    end
  end

  def add_private_files(zip)
    require "find"
    Find.find("#{@output_dir}/files") do |path|
      entry = path.sub(/.*\/(files\/?)/, '\\1')
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
      next if /^#{site_fs_path}/.match?(path)
      next if @exclude_public_files.include?(path)

      entry = path.sub(/^#{@site_dir}/, 'public')
      if File.directory?(path)
        zip.mkdir(entry)
      else
        zip.add(entry, path)
      end
    end
  end
end
