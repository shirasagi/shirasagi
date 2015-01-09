require "open3"

class Voice::MainController < ApplicationController
  public
    def index
      if SS.config.voice.disable
        head :not_found
        return
      end

      url = get_and_normalize_path
      if url.host.blank? || url.path.blank?
        # path must not be either nil, empty.
        logger.debug("malformed url: #{url}")
        head :bad_request
        return
      end

      voice_file = Voice::VoiceFile.find_or_create_by_url url
      unless voice_file
        head :not_found
        return
      end

      if voice_file.latest?
        send_audio_file(file: voice_file.file, timestamp: voice_file.last_modified)
        return
      end

      begin
        # check for whether given url can download
        voice_file.download
      rescue
        # http errors like 404 or 500.
        if voice_file.exists?
          send_audio_file(file: voice_file.file, timestamp: voice_file.last_modified)
          return
        end

        # do not record http errors like 404.
        voice_file.destroy
        head :not_found
        return
      end

      voice_file = Voice::VoiceFile.acquire_lock voice_file.id
      if voice_file
        # create voice file in background if successfully acquire lock
        Voice::SynthesisJob.call_async voice_file.id do |job|
          job.site_id = voice_file.site_id
        end
        run_job
      end

      head :accepted, retry_after: SS.config.voice.controller["retry_after"]
    end

  private
    def get_and_normalize_path
      path = params[:path]
      path = ::URI.unescape(path) if path.include?("%3A%2F%2F")
      url = ::URI.parse(path)
      url.normalize!
      url
    end

    def send_audio_file(opts)
      file = opts[:file]
      return unless file

      timestamp = opts.key?(:timestamp) ? opts["timestamp"] : nil
      timestamp ||= Fs.stat(file).mtime

      response.headers["Content-Type"] = "audio/mpeg"
      response.headers["Last-Modified"] = CGI::rfc1123_date(timestamp)
      send_file file, disposition: :inline, x_sendfile: true
    end

    def run_job
      # run job in other process which does not wait for exit.
      cmd = "bundle exec rake job:run RAILS_ENV=#{Rails.env}"
      logger.debug("system: #{cmd}")
      stdin, stdout, stderr = Open3.popen3(cmd)
    end
end
