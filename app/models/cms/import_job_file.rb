class Cms::ImportJobFile
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include Cms::Reference::Site
  include Cms::Reference::Node

  attr_accessor :in_file, :import_logs, :name, :basename

  seqid :id
  field :import_date, type: DateTime
  embeds_ids :files, class_name: "SS::File"

  permit_params :in_file, :name, :basename, :import_date
  validates :in_file, presence: true
  validates :import_date, presence: true

  before_validation :set_import_date
  before_save :save_files

  public
    def save_with_import
      if !cur_node
        # save root node
        root_node = Cms::Node::ImportNode.new
        root_node.filename = basename
        root_node.name = name
        root_node.cur_site = cur_site
        root_node.group_ids = cur_user.group_ids

        if root_node.save
          self.cur_node = root_node
        else
          self.errors.add :base, I18n.t("errors.messages.root_node_save_error")
          root_node.errors.full_messages.each do |e|
            self.errors.add :base, e
          end
          return false
        end
      end

      if save
        Cms::ImportFilesJob.bind(site_id: site.id).perform_later()
        return true
      else
        self.import_date = nil
        return false
      end
    end

    def import
      @import_logs = []
      files.each do |file|
        if ::File.extname(file.filename) =~ /^\.zip$/i
          import_from_zip(file)
        else
          import_from_file(file)
        end
      end
    end

    def save_import_page(file, import_filename)
      import_html = file.read.force_encoding("utf-8").scrub
      import_html = modify_relative_paths(import_html)

      item = Cms::ImportPage.new
      item.filename = import_filename
      item.name = ::File.basename(import_filename)
      item.html = import_html
      item.cur_site = site
      item.group_ids = user.group_ids
      item.save

      set_errors(item, import_filename)
      return item.errors.empty?
    end

    def save_import_node(file, import_filename)
      item = Cms::Node::ImportNode.new
      item.filename = import_filename
      item.name = ::File.basename(import_filename)
      item.cur_site = site
      item.group_ids = user.group_ids
      item.save

      set_errors(item, import_filename)
      return item.errors.empty?
    end

    def upload_import_file(file, import_filename)
      import_path = "#{site.path}/#{import_filename}"

      item = Uploader::File.new(path: import_path, binary: file.read, site: site)
      item.save

      set_errors(item, import_filename)
      return item.errors.empty?
    end

    def set_errors(item, import_filename)
      item.errors.each do |n, e|
        if n == :filename
          @import_logs << "error: #{import_filename}#{e}"
          self.errors.add :base, "#{item.filename}#{e}"
        elsif n == :name
          @import_logs << "error: #{import_filename}#{e}"
          self.errors.add :base, "#{import_filename}#{e}"
        else
          @import_logs << "error: #{import_filename} #{item.class.t(n)}#{e}"
          self.errors.add :base, "#{import_filename} #{item.class.t(n)}#{e}"
        end
      end
    end

    def import_from_zip(file, opts = {})
      Zip::Archive.open(file.path) do |ar|
        ar.each do |f|
          fname = f.name.force_encoding("utf-8").scrub.split(/\//)
          fname.shift # remove root folder
          fname = fname.join("\/")
          next if fname.blank?

          import_filename = "#{node.filename}/#{fname}"
          import_filename = import_filename.sub(/\/$/, "")

          if f.directory?
            if save_import_node(f, import_filename)
              @import_logs << "import: #{import_filename}"
            end
          elsif ::File.extname(import_filename) =~ /^\.(html|htm)$/i
            if save_import_page(f, import_filename)
              @import_logs << "import: #{import_filename}"
            end
          elsif upload_import_file(f, import_filename)
            @import_logs << "import: #{import_filename}"
          end
        end
      end

      return errors.empty?
    end

    def import_from_file(file, opts = {})
      import_filename = "#{node.filename}/#{file.filename}"

      if ::File.extname(import_filename) =~ /^\.(html|htm)$/i
        if save_import_page(file, import_filename)
          @import_logs << "import: #{import_filename}"
        end
      elsif upload_import_file(file, import_filename)
        @import_logs << "import: #{import_filename}"
      end

      return errors.empty?
    end

    def modify_relative_paths(html)
      html.gsub(/(href|src)="\/(.*?)"/) do
        attr = $1
        path = $2
        "#{attr}=\"\/#{node.filename}/#{path}\""
      end
    end

  private
    def save_files
      item = SS::File.new
      item.in_file = in_file
      item.site = site
      item.state = "closed"
      item.name = name
      item.model = "cms/import_file"
      item.save!

      self.file_ids = [item.id]
    end

    def set_import_date
      self.import_date ||= Time.zone.now
    end
end
