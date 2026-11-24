class Opendata::UrlResource
  include SS::Document
  include Opendata::Resource::Model
  include Opendata::Resource::Previewable
  include Opendata::Addon::UrlRdfStore
  include Opendata::Addon::Harvest::Resource
  include Opendata::Addon::Metadata::Resource
  include History::Addon::Backup

  field :original_url, type: String
  field :original_updated, type: DateTime
  field :crawl_state, type: String, default: "same"
  field :crawl_update, type: String

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :url_resources

  permit_params :name, :text, :license_id, :original_url, :crawl_update

  after_validation :destroy_download_temp_file, if: -> { @download_temp_file }

  validates :original_url, presence: true, url: true
  validate :validate_original_url, if: -> { original_url.present? }
  validates :original_updated, presence: true
  validates :crawl_state, presence: true
  validates :crawl_update, presence: true

  after_save -> { dataset.save(validate: false) }
  after_destroy -> { dataset.save(validate: false) }

  class << self
    def context_path
      "/url_resource"
    end
  end

  delegate :context_path, to: :class

  def crawl_update_options
    [
      [I18n.t("opendata.crawl_update_name.none"), "none"],
      [I18n.t("opendata.crawl_update_name.auto"), "auto"]
    ]
  end

  def do_crawl(time_out: nil)
    puts self.original_url

    url = ::URI.parse(self.original_url) rescue nil
    return if url.blank?

    temp_file, last_modified = Opendata.download_url!(url, timeout: time_out)
    temp_file.close(true) if temp_file
    if self.crawl_update == "none"
      do_crawl_none(last_modified)
    elsif self.crawl_update == "auto"
      do_crawl_auto(last_modified)
    end
  rescue Timeout::Error
    puts I18n.t("opendata.errors.messages.invalid_timeout")
  rescue => e
    puts "Error: #{e}"
    self.crawl_state = "deleted"
    self.save(validate: false)
  end

  private

  def do_crawl_none(last_modified)
    if last_modified.present?
      if self.original_updated.blank?
        self.crawl_state = "updated"
      elsif last_modified.to_i > self.original_updated.to_i
        self.crawl_state = "updated"
      elsif last_modified.to_i <= self.original_updated.to_i
        self.crawl_state = "same"
      end
      self.original_updated = last_modified
    else
      puts "no file or no last_modified"
      self.crawl_state = "deleted"
    end

    res = self.save(validate: false)
    if res == true
      puts "success"
    else
      puts "failure"
    end
  end

  def do_crawl_auto(last_modified)
    return if last_modified.blank?
    return if last_modified.to_i <= self.original_updated.to_i

    self.crawl_state = "same"
    # validate_original_url method is called inside save method,
    # and then download resource from internet and save it locally.
    self.save
  end

  def validate_original_url
    return if errors[:original_url].present?

    begin
      uri = ::URI.parse(original_url)
    rescue => e
      errors.add :original_url, :invalid
      return
    end

    if uri.path == '/'
      errors.add :original_url, :invalid
      return
    end

    if in_file.present?
      # set file manually from in_file

      self.original_updated = Time.zone.now
      self.filename = in_file.original_filename
      self.crawl_state = "same"
    else
      # download file from original_url
      begin
        temp_file, last_modified = Opendata.download_url!(uri)

        self.original_updated = last_modified
        self.filename = temp_file.original_filename

        @download_temp_file = SS::File.new
        @download_temp_file.in_file = temp_file
        @download_temp_file.site_id = dataset.site_id
        @download_temp_file.model = self.class.to_s.underscore

        @download_temp_file.content_type = self.format = self.filename.sub(/.*\./, "").upcase
        @download_temp_file.filename = self.filename
        @download_temp_file.owner_item = dataset

        if @download_temp_file.save
          self.file.destroy if file
          self.file_id = @download_temp_file.id
        end

        self.crawl_state = "same"
      rescue Timeout::Error => e
        logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        errors.add :base, I18n.t("opendata.errors.messages.invalid_timeout")
      rescue => e
        logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        errors.add :original_url, :invalid
      end
    end
  end

  def destroy_download_temp_file
    return if self.errors.blank?
    @download_temp_file.destroy
  end
end
