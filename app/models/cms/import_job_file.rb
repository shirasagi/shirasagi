class Cms::ImportJobFile
  extend SS::Translation
  include SS::Document
  include SS::Reference::User
  include Cms::Reference::Site

  attr_accessor :name, :basename
  attr_accessor :in_file, :import_logs

  seqid :id
  field :import_date, type: DateTime
  belongs_to :node, class_name: "Cms::Node"
  embeds_ids :files, class_name: "SS::File"

  permit_params :in_file, :name, :basename, :import_date

  validates :in_file, presence: true

  validate :validate_root_node, if: -> { !node }
  validate :validate_in_file, if: -> { in_file }

  before_save :set_import_date
  before_save :save_root_node, if: -> { @root_node }
  before_save :save_in_file, if: -> { @import_file }

  after_save :perform_job, if: -> { @import_job }

  def save_with_import
    @import_job = true
    save
  end

  def import
    @import_logs = []
    files.each do |file|
      if /^\.zip$/i.match?(::File.extname(file.filename))
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
    Zip::File.open(file.path) do |archive|
      archive.each do |entry|
        next if entry.name.start_with?('__MACOSX')

        fname = entry.name.force_encoding("utf-8").scrub.split(/\//)
        fname.shift # remove root folder
        fname = fname.join('/')
        next if fname.blank?

        import_filename = "#{node.filename}/#{fname}"
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

  def import_from_file(file, opts = {})
    import_filename = "#{node.filename}/#{file.filename}"

    if /^\.(html|htm)$/i.match?(::File.extname(import_filename))
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

  def perform_job
    job = Cms::ImportFilesJob.bind(site_id: site.id)
    job = job.set(wait_until: import_date) if import_date.present?
    job.perform_later
  end

  private

  def set_import_date
    self.import_date ||= Time.zone.now
  end

  def validate_root_node
    @root_node = Cms::Node::ImportNode.new
    @root_node.filename = basename
    @root_node.name = name
    @root_node.cur_site = cur_site
    @root_node.group_ids = cur_user.group_ids if cur_user
    return if @root_node.valid?

    self.errors.add :base, I18n.t("errors.messages.root_node_save_error")
    @root_node.errors.full_messages.each { |e| self.errors.add :base, e }
  end

  def validate_in_file
    @import_file = SS::File.new
    @import_file.in_file = in_file
    @import_file.site = cur_site
    @import_file.state = "closed"
    @import_file.name = name
    @import_file.model = "cms/import_file"

    v = @import_file.valid?
    return if v

    @import_file.errors.full_messages.each { |e| self.errors.add :base, e }
  end

  def save_in_file
    @import_file.save!
    self.file_ids = [@import_file.id]
  end

  def save_root_node
    @root_node.save!
    self.node = @root_node
  end
end
