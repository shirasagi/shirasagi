class Opendata::Appfile
  include SS::Document
  include SS::Relation::File
  include Opendata::TsvParseable
  include Opendata::AllowableAny
  include Opendata::Common

  attr_accessor :workflow, :status

  seqid :id
  field :filename, type: String
  field :text, type: String
  field :format, type: String

  embedded_in :app, class_name: "Opendata::App", inverse_of: :appfile
  belongs_to_file :file

  permit_params :text

  validates :in_file, presence: true, if: ->{ file_id.blank? }
  validates :filename, uniqueness: true
  validate :validate_appfile

  before_validation :set_filename, if: ->{ in_file.present? }

  before_save :before_save_file
  after_save :save_app
  after_destroy -> { app.save(validate: false) }

  def url
    get_app_url(app, "/appfile/#{id}/#{URI.escape(filename)}")
  end

  def full_url
    get_app_full_url(app, "/appfile/#{id}/#{URI.escape(filename)}")
  end

  def content_url
    get_app_full_url(app, "/appfile/#{id}/content.html")
  end

  def json_url
    get_app_full_url(app, "/appfile/#{id}/json.html")
  end

  def path
    file ? file.path : nil
  end

  def content_type
    file ? file.content_type : nil
  end

  def size
    file ? file.size : nil
  end

  private

  def set_filename
    self.filename = in_file.original_filename
    self.format = filename.sub(/.*\./, "").upcase
  end

  def validate_appfile
    if self.app.appurl.present?
      errors.clear
      errors.add :file_id, I18n.t("opendata.errors.messages.validate_appfile")
      return
    end
  end

  def before_save_file
    if file_id_was.present? && file_id_was != file_id
      old_file = SS::File.find(file_id_was) rescue nil
      old_file.destroy if old_file
    end

    return if file.blank?

    if @new_clone
      attributes = Hash[file.attributes]
      attributes.select!{ |k| file.fields.key?(k) }

      attributes["user_id"] = @cur_user.id if @cur_user
      attributes["_id"] = nil
      clone_file = SS::File.create_empty!(attributes, validate: false) do |new_file|
        ::FileUtils.copy(file.path, new_file.path)
      end
      clone_file.owner_item = _parent
      clone_file.save(validate: false)
      self.file = clone_file
    end

    attrs = {}

    if file.site_id != _parent.site_id
      attrs[:site_id] = _parent.site_id
    end
    if file.model != _parent.class.name
      attrs[:model] = _parent.class.name
    end
    if file.owner_item != _parent
      attrs[:owner_item] = _parent
    end
    if file.state != _parent.state
      attrs[:state] = _parent.state
    end

    if attrs.present?
      file.update(attrs)
    end
  end

  def save_app
    self.workflow ||= {}
    app.cur_site = app.site
    app.apply_status(status, workflow) if status.present?
    app.released ||= Time.zone.now
    app.save(validate: false)
  end

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      criteria = criteria.where(filename: /#{::Regexp.escape(params[:keyword])}/) if params[:keyword].present?

      criteria
    end
  end
end
