class Opendata::UrlResource
  include SS::Document
  include Opendata::Resource::Model
  include SS::Relation::File
  include Opendata::Addon::UrlRdfStore

  field :original_url, type: String
  field :original_updated, type: DateTime
  field :crawl_state, type: String, default: "same"
  field :crawl_update, type: String

  embedded_in :dataset, class_name: "Opendata::Dataset", inverse_of: :url_resource

  permit_params :name, :text, :license_id, :original_url, :crawl_update

  validates :crawl_update, presence: true

  validate :validate_original_url

  after_save -> { dataset.save(validate: false) }
  after_destroy -> { dataset.save(validate: false) }

  def context_path
    "/url_resource"
  end

  def crawl_update_options
    [
      [I18n.t("opendata.crawl_update_name.none"), "none"],
      [I18n.t("opendata.crawl_update_name.auto"), "auto"]
    ]
  end

  def do_crawl(time_out: 30)
    require 'net/http'
    require "open-uri"

    puts self.original_url

    last_modified = Timeout.timeout(time_out) do
      open(self.original_url, proxy: true) { |url_file| url_file.last_modified }
    end

    if last_modified.blank?
      last_modified = Time.zone.now
    end

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
    uri = URI.parse(original_url)
    if uri.path == '/'
      errors.add :original_url, :invalid
      return
    end

    Tempfile.open('temp') do |temp_file|
      last_modified = download_to(temp_file)
      break if last_modified.blank?

      self.original_updated = last_modified
      self.filename = ::File.basename(uri.path) if self.filename.blank?

      ss_file = SS::File.new
      ss_file.in_file = ActionDispatch::Http::UploadedFile.new(tempfile: temp_file,
                                                               filename: self.filename,
                                                               type: 'application/octet-stream')
      ss_file.model = self.class.to_s.underscore

      ss_file.content_type = self.format = self.filename.sub(/.*\./, "").upcase
      ss_file.filename = self.filename
      ss_file.save
      send("file_id=", ss_file.id)
      self.crawl_state = "same"
    end
  rescue Timeout::Error => e
    logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    errors.add :base, I18n.t("opendata.errors.messages.invalid_timeout")
  rescue => e
    logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    errors.add :original_url, :invalid
  ensure
    in_file.close(true) if in_file
  end

  def download_to(temp_file, time_out: 30)
    require 'net/http'
    require "open-uri"
    require "resolv-replace"
    require 'timeout'
    require 'nkf'

    temp_file.binmode
    Timeout.timeout(time_out) do
      open(original_url, proxy: true) do |data|

        data.binmode
        temp_file.write(data.read)
        temp_file.rewind

        content_disposition = data.meta['content-disposition']
        content_disposition = "Content-Disposition: attachment; filename= " if content_disposition.blank?
        self.filename = NKF.nkf "-w", content_disposition.match(/filename=(\"?)(.+)\1/)[2].to_s

        if data.last_modified.blank?
          break Time.zone.now
        else
          break data.last_modified
        end
      end
    end
  end
end

