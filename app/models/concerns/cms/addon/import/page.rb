require 'kconv'
require 'zip'

module Cms::Addon::Import
  module Page
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_file, :root_files, :import_date, :imported
      permit_params :in_file, :root_files, :import_date

      validates :in_file, presence: true, on: :import
    end

    def import
      @imported = 0
      return false if in_file.blank?

      if ::File.extname(in_file.original_filename) =~ /^\.zip$/i
        import_from_zip(root_files: root_files.present?)
      else
        import_from_file
      end
    end

    def save_with_import
      @imported = 0
      return false unless save(context: :import)
      return import
    end

    private

    def save_import_page(file, import_filename)
      import_html = file.read.force_encoding("utf-8")
      import_html = modify_relative_paths(import_html)

      item = Cms::ImportPage.new
      item.filename = import_filename
      item.name = ::File.basename(import_filename)
      item.html = import_html
      item.cur_site = @cur_site
      item.group_ids = group_ids
      item.save

      set_errors(item, import_filename)
      return item.errors.empty?
    end

    def save_import_node(file, import_filename)
      item = Cms::Node::ImportNode.new
      item.filename = import_filename
      item.name = ::File.basename(import_filename)
      item.cur_site = @cur_site
      item.group_ids = group_ids
      item.save

      set_errors(item, import_filename)
      return item.errors.empty?
    end

    def upload_import_file(file, import_filename)
      import_path = "#{@cur_site.path}/#{import_filename}"

      item = Uploader::File.new(path: import_path, binary: file.read)
      item.save

      set_errors(item, import_filename)
      return item.errors.empty?
    end

    def set_errors(item, import_filename)
      item.errors.each do |n, e|
        if n == :filename
          self.errors.add :base, "#{item.filename}#{e}"
        elsif n == :name
          self.errors.add :base, "#{import_filename}#{e}"
        else
          self.errors.add :base, "#{import_filename} #{item.class.t(n)}#{e}"
        end
      end
    end

    def import_from_zip(opts = {})
      root_files = (opts[:root_files] == true)

      Zip::File.open(in_file.path) do |archive|
        archive.each do |entry|
          fname = entry.name.toutf8.split(/\//)
          fname.shift unless root_files
          fname = fname.join('/')
          next if fname.blank?

          import_filename = "#{self.filename}/#{fname}"
          import_filename = import_filename.sub(/\/$/, "")

          if entry.directory?
            @imported += 1 if save_import_node(entry.get_input_stream, import_filename)
          elsif ::File.extname(import_filename) =~ /^\.(html|htm)$/i
            @imported += 1 if save_import_page(entry.get_input_stream, import_filename)
          elsif upload_import_file(entry.get_input_stream, import_filename)
            @imported += 1
          end
        end
      end

      return errors.empty?
    end

    def import_from_file
      import_filename = "#{self.filename}/#{in_file.original_filename}"

      if ::File.extname(import_filename) =~ /^\.(html|htm)$/i
        @imported += 1 if save_import_page(in_file, import_filename)
      elsif upload_import_file(in_file, import_filename)
        @imported += 1
      end

      return errors.empty?
    end

    def modify_relative_paths(html)
      html.gsub(/(href|src)="\/(.*?)"/) do
        attr = $1
        path = $2
        "#{attr}=\"\/#{self.filename}/#{path}\""
      end
    end
  end
end
