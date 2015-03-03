require "open3"

class Voice::MainController < ApplicationController
  before_action :check_voice_disable
  before_action :set_url
  before_action :lock_voice_file

  private
    def check_voice_disable
      # raise "404" if SS.config.voice.disable
      if SS.config.voice.disable
        head :not_found
      end
    end

    def set_url
      @url = get_and_normalize_path
      if @url.host.blank? || @url.path.blank?
        # path must not be either nil, empty.
        logger.debug("malformed url: #{@url}")
        # raise "400"
        head :bad_request
      end
    end

    def lock_voice_file
      voice_file = Voice::VoiceFile.find_or_create_by_url @url
      # raise "404"
      unless voice_file
        head :not_found
      end

      @voice_file = Voice::VoiceFile.acquire_lock voice_file
      unless @voice_file
        head :accepted, retry_after: SS.config.voice.controller["retry_after"]
        return
      end
    end

  public
    def index
      if @voice_file.latest?
        Voice::VoiceFile.release_lock @voice_file
        send_audio_file(@voice_file.file)
        return
      end

      # check for whether be able to download.
      @voice_file.download

      # create voice file in background if successfully acquire lock
      # and do not release lock while voice is creating.
      Voice::SynthesisJob.call_async @voice_file.id do |job|
        job.site_id = @voice_file.site_id
      end
      SS::RakeRunner.run_async "job:run", "RAILS_ENV=#{Rails.env}"
      head :accepted, retry_after: SS.config.voice.controller["retry_after"]
    rescue => e
      logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")

      # http errors like 404 or 500.
      if @voice_file.exists?
        Voice::VoiceFile.release_lock @voice_file
        send_audio_file(@voice_file.file)
        return
      end

      # do not record http errors like 404.
      @voice_file.destroy
      head :not_found
      return
    end

  private
    def get_and_normalize_path
      path = params[:path]
      path = ::URI.unescape(path) if path.include?("%3A%2F%2F")
      url = ::URI.parse(path)
      url.normalize!
      url
    end

    def send_audio_file(file)
      return unless file
      timestamp = Fs.stat(file).mtime

      response.headers["Content-Type"] = "audio/mpeg"
      response.headers["Last-Modified"] = CGI::rfc1123_date(timestamp)

      if Fs.mode == :grid_fs
        return send_data Fs.binread(file)
      end

      # x_sendfile requires a instance which implements 'to_path' method.
      # see: Rack::Sendfile#call(env)
      file = ::File.new(file) unless file.respond_to?(:to_path)
      send_file file, disposition: :inline, x_sendfile: true
    end
end
