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
  include Voice::Lockable

  store_in collection: "voice_files"

  # permissions are delegated to edit_cms_users.
  set_permission_name :cms_users, :edit

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

      def save_term_options
        [
          [I18n.t(:"history.save_term.day"), "day"],
          [I18n.t(:"history.save_term.month"), "month"],
          [I18n.t(:"history.save_term.year"), "year"],
          [I18n.t(:"history.save_term.all_save"), "all_save"],
        ]
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

    def latest?(margin = 60)
      return false unless exists?

      # check for whether file is fresh enough to prevent infinite loops in voice synthesis.
      return true if fresh?(margin)

      download

      # check for whether this has same identity
      return false unless same_identity?

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
      self.class.ensure_release_lock(self) do
        begin
          download
          unless force
            if self.latest?
              # voice file is up-to-date
              Rails.logger.info("voice file up-to-date: #{self.url}")
              break
            end
          end

          Fs.mkdir_p(::File.dirname(self.file))
          Voice::Converter.convert(self.site_id, @cached_page.html, self.file)

          self.page_identity = @cached_page.page_identity
          self.error = nil
          # incrementing age ensures that 'updated' field is updated.
          self.age += 1
          self.save!
        rescue OpenURI::HTTPError
          raise
        rescue Exception => e
          self.page_identity = nil
          self.error = e.to_s
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

    def fresh?(margin)
      elapsed = Time.now - Fs.stat(file).mtime
      elapsed < margin
    end
end
