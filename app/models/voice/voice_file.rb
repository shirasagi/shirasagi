require 'digest'
require 'open-uri'
require 'resolv-replace'
require 'timeout'

class Voice::VoiceFile
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission
  include Voice::Downloadable

  store_in collection: "voice_files"

  # permissions are delegated to edit_cms_users.
  set_permission_name :cms_users, :edit

  field :path, type: String
  field :url, type: String
  field :last_modified, type: DateTime
  field :lock_until, type: DateTime, default: 0
  field :error, type: String
  field :has_error, type: Integer, default: 0
  field :age, type: Integer, default: 0

  scope :search, ->(params) do
    criteria = self.where({})

    if params.present?
      save_term = params[:keyword]
      if save_term.present?
        from = History::Log.term_to_date save_term
        criteria = criteria.lt(created: from) if from
      end

      keyword = params[:keyword]
      criteria = criteria.keyword_in keyword, :url if keyword.present?

      has_error = params[:has_error]
      if has_error.present?
        has_error = has_error.to_i if has_error.kind_of? String
        criteria = criteria.where(has_error: 1) if has_error != 0
      end
    end

    criteria
  end

  before_save :set_has_error
  after_destroy :delete_file

  class << self
    public
      def root
        File.expand_path(SS.config.voice.root, Rails.root)
      end

      def acquire_lock(id)
        criteria = Voice::VoiceFile.where(id: id)
        criteria = criteria.lt(lock_until: Time.now)
        criteria.find_and_modify({ '$set' => { lock_until: 5.minutes.from_now }}, new: true)
      end

      def release_lock(id)
        voice_file = Voice::VoiceFile.find(id) rescue nil
        if voice_file
          voice_file.lock_until = Time.at(0)
          voice_file.save!
        end
      end

      def find_or_create_by_url(url)
        url = ::URI.parse(url.to_s) unless url.respond_to?(:host)
        if url.host.blank? || url.path.blank?
          # path must not be either nil, empty.
          Rails.logger.debug("malformed url: #{url}")
          return nil
        end
        url.normalize!

        site = find_site url
        unless site
          Rails.logger.debug("site is not found: #{url}")
          return nil
        end

        path = url.query.blank? ? url.path : "#{path}?#{url.query}"
        voice_file = Voice::VoiceFile.find_or_create_by site_id: site.id, path: path
        if voice_file.url.blank?
          voice_file.url = url.to_s
          voice_file.save!
        end
        voice_file
      end

      def save_term_options
        [
          [I18n.t(:"history.save_term.day"), "day"],
          [I18n.t(:"history.save_term.month"), "month"],
          [I18n.t(:"history.save_term.year"), "year"],
          [I18n.t(:"history.save_term.all_save"), "all_save"],
        ]
      end

    private
      def find_site(url)
        host = url.host
        port = url.port

        SS::Site.find_by_domain("#{host}:#{port}") || SS::Site.find_by_domain("#{host}")
      end
  end

  public
    def file
      site_part = site_id.to_s.split(//).join("/")
      id_part = Digest::SHA1.hexdigest(id.to_s).scan(/.{1,2}/).shift(2).join("/")
      file_part = "#{id}.mp3"

      "#{self.class.root}/voice_files/#{site_part}/#{id_part}/_/#{file_part}"
    end

    def exists?
      Fs.exists?(file)
    end

    def latest?
      return false unless exists?

      @html, @last_modified = download unless @html

      # check for whether source is updated.
      return false if self.last_modified < @last_modified

      # check for whether kana dictionary is updated.
      Kana::Dictionary.pull(self.site_id) do |kanadic|
        if kanadic
          kanadic_modified = ::File.mtime(kanadic)
          file_modified = Fs.stat(self.file).mtime
          return false if file_modified < kanadic_modified
        end
      end

      # this one is latest.
      true
    end

    def synthesize(force = false)
      ensure_release_lock do
        begin
          @html, @last_modified = self.download
          unless force
            if self.latest?
              # voice file is up-to-date
              Rails.logger.info("voice file up-to-date: #{self.url}")
              break
            end
          end

          Fs.mkdir_p(::File.dirname(self.file))
          Voice::Converter.convert(self.site_id, @html, self.file)

          self.last_modified = @last_modified
          self.error = nil
          # incrementing age ensures that 'updated' field is updated.
          self.age += 1
          self.save!
        rescue OpenURI::HTTPError
          raise
        rescue
          self.last_modified = nil
          self.error = $ERROR_INFO.to_s
          # incrementing age ensures that 'updated' field is updated.
          self.age += 1
          guard_from_exception(self.url) do
            self.save!
          end
          raise
        end
      end

      true
    end

  private
    def ensure_release_lock
      begin
        ret = yield
      ensure
        self.class.release_lock id
      end
      ret
    end

    def set_has_error
      self.has_error = self.error.blank? ? 0 : 1
    end

    def delete_file
      file = self.file
      Fs.rm_rf(file) if exists?
    end

    def guard_from_exception(message, klass = Mongoid::Errors::MongoidError)
      begin
        yield
      rescue klass => e
        Rails.logger.error("#{message}: #{e.class} (#{e.message}):\n  #{e.backtrace[0..5].join('\n  ')}")
      end
    end
end
