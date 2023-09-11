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
    @import_pages = {}
    @import_nodes = {}
    @import_files = {}

    files.each do |file|
      import_from_zip(file)
    end
  end

  def save_import_node(filename)
    item = Cms::Node::ImportNode.new
    item.filename = filename
    item.name = ::File.basename(filename)
    item.cur_site = site
    item.group_ids = user.group_ids

    if item.save
      @import_nodes[filename] = item
      @import_logs << "import: #{filename}"
      return item
    else
      set_errors(filename, item)
      return nil
    end
  end

  def save_import_page(filename, file)
    import_html = file.read.force_encoding("utf-8").scrub
    import_html = modify_relative_paths(import_html)

    item = Cms::ImportPage.new
    item.filename = filename
    item.name = ::File.basename(filename)
    item.html = import_html
    item.cur_site = site
    item.group_ids = user.group_ids

    if item.save
      @import_pages[filename] = item
      @import_logs << "import: #{filename}"
      return item
    else
      set_errors(filename, item)
      return nil
    end
  end

  def upload_import_file(filename, file)
    import_path = "#{site.path}/#{filename}"
    item = Uploader::File.new(path: import_path, binary: file.read, site: site)

    if item.save
      @import_files[filename] = item
      @import_logs << "import: #{filename}"
      return item
    else
      set_errors(filename, item)
      return nil
    end
  end

  def set_errors(filename, item)
    item.errors.each do |error|
      attribute = error.attribute
      message = error.message

      case attribute
      when :filename
        @import_logs << "error: #{filename} #{message}"
        self.errors.add :base, "#{item.filename} #{message}"
      when :name
        @import_logs << "error: #{filename} #{message}"
        self.errors.add :base, "#{filename} #{message}"
      else
        name = attribute == :base ? '' : item.class.t(attribute)
        @import_logs << "error: #{filename} #{name}#{message}"
        self.errors.add :base, "#{filename} #{name}#{message}"
      end
    end
  end

  def entry_to_filename(entry)
    filename = entry.name.force_encoding("utf-8").scrub
    return if filename.blank?

    virtual_path = "/$"
    filename = ::File.expand_path(filename, virtual_path)
    return if !filename.start_with?("/$/")
    filename = filename[3..-1]

    return if filename.blank?
    return if filename.include?('__MACOSX')
    return if filename.include?('.DS_Store')

    filename
  end

  def import_from_zip(file)
    Zip::File.open(file.path) do |archive|
      archive.each do |entry|
        next if entry.directory?

        filename = entry_to_filename(entry)
        next if filename.blank?

        # relative basedir
        @basedir = filename.index("/") ? filename.split("/").first : root_node.filename
        @basedir = ::File.join(root_node.filename, @basedir) if @basedir != root_node.filename

        # prepend root node filename
        filename = filename.delete_prefix("#{root_node.basename}/")
        filename = ::File.join(root_node.filename, filename)

        # import parent dirs
        filename.split("/").inject do |filename, item|
          if filename.start_with?("#{root_node.filename}/") && !@import_nodes[filename]
            save_import_node(filename)
          end
          "#{filename}/#{item}"
        end

        # import page or files
        if /^\.(html|htm)$/i.match?(::File.extname(filename))
          save_import_page(filename, entry.get_input_stream)
        else
          upload_import_file(filename, entry.get_input_stream)
        end
      end
    end

    return errors.empty?
  end

  def modify_relative_paths(html)
    html.gsub(/(href|src)="\/(.*?)"/) do
      attr = $1
      path = $2
      "#{attr}=\"\/#{@basedir}/#{path}\""
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
