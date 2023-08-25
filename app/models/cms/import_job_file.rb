class Cms::ImportJobFile
  extend SS::Translation
  include SS::Document
  include SS::SanitizerJobFile
  include SS::Reference::User
  include Cms::Reference::Site
  include Cms::Reference::Node

  attr_accessor :name, :basename, :in_file, :import_logs

  seqid :id
  field :import_date, type: DateTime
  belongs_to :root_node, class_name: "Cms::Node"
  embeds_ids :files, class_name: "SS::File"

  permit_params :in_file, :name, :basename, :import_date

  validate :validate_root_node
  validate :validate_in_file

  before_save :set_import_date
  before_save :save_root_node, if: -> { @root_node }
  before_save :save_in_file, if: -> { @import_file }
  after_save :perform_job, if: -> { @import_job }
  after_destroy :destroy_files

  def save_with_import
    @import_job = true
    save
  end

  def import
    @import_logs = []
    files.each do |file|
      import_from_zip(file)
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
    item.errors.each do |error|
      attribute = error.attribute
      message = error.message

      case attribute
      when :filename
        @import_logs << "error: #{import_filename} #{message}"
        self.errors.add :base, "#{item.filename} #{message}"
      when :name
        @import_logs << "error: #{import_filename} #{message}"
        self.errors.add :base, "#{import_filename} #{message}"
      else
        name = attribute == :base ? '' : item.class.t(attribute)
        @import_logs << "error: #{import_filename} #{name}#{message}"
        self.errors.add :base, "#{import_filename} #{name}#{message}"
      end
    end
  end

  def import_from_zip(file)
    Zip::File.open(file.path) do |archive|
      archive.each do |entry|
        filename = entry.name.force_encoding("utf-8").scrub
        next if filename.blank?

        virtual_path = "/$"
        filename = ::File.expand_path(filename, virtual_path)
        next unless filename.start_with?("/$/")

        filename = filename[3..-1]
        filename = filename.delete_prefix("#{root_node.basename}/") # remove root folder
        next if filename.blank?
        next if filename.start_with?('__MACOSX')
        next if filename.start_with?('.DS_Store')

        import_filename = "#{root_node.filename}/#{filename}"
        import_filename = import_filename.sub(/\/$/, "")

        if entry.directory?
          if save_import_node(entry.get_input_stream, import_filename)
            @import_logs << "import: #{import_filename}"
          end
        elsif /^\.(html|htm)$/i.match?(::File.extname(import_filename))
          if save_import_page(entry.get_input_stream, import_filename)
            @import_logs << "import: #{import_filename}"
          end
        elsif upload_import_file(entry.get_input_stream, import_filename)
          @import_logs << "import: #{import_filename}"
        end
      end
    end

    return errors.empty?
  end

  def modify_relative_paths(html)
    html.gsub(/(href|src)="\/(.*?)"/) do
      attr = $1
      path = $2
      "#{attr}=\"\/#{root_node.filename}/#{path}\""
    end
  end

  def perform_job
    job_bindings = { site_id: site.id }
    job_bindings[:node_id] = node.id if node

    job = Cms::ImportFilesJob.bind(job_bindings)
    job = job.set(wait_until: import_date) if import_date.present?
    job_class = sanitizer_job(job).perform_later

    set(job_name: job_class.job_id, job_wait: job.job_wait)
  end

  private

  def presence_node_id
    false
  end

  def set_import_date
    self.import_date ||= Time.zone.now
  end

  def validate_root_node
    errors.add :name, :blank if name.blank?
    errors.add :basename, :blank if basename.blank?
    return if errors.present?

    @root_node = Cms::Node::ImportNode.new
    @root_node.filename = basename
    @root_node.name = name
    @root_node.cur_site = cur_site
    @root_node.cur_node = cur_node if cur_node
    @root_node.group_ids = cur_site.group_ids
    return if @root_node.valid?

    self.errors.add :base, I18n.t("errors.messages.root_node_save_error")
    SS::Model.copy_errors(@root_node, self)
  end

  def validate_in_file
    if in_file.nil? || ::File.extname(in_file.original_filename) != ".zip"
      errors.add :base, :invalid_zip
      return
    end

    @import_file = SS::File.new
    @import_file.in_file = in_file
    @import_file.site = cur_site
    @import_file.state = "closed"
    @import_file.name = name
    @import_file.model = "cms/import_file"
    return if @import_file.valid?

    SS::Model.copy_errors(@import_file, self)
  end

  def save_in_file
    @import_file.save!
    self.file_ids = [@import_file.id]
  end

  def save_root_node
    @root_node.save!
    self.root_node = @root_node
  end

  def destroy_files
    files.destroy_all
  end
end
