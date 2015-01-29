module Voice
  class WavToMp3Error < RuntimeError
  end

  class WavToMp3
    public
      def initialize(config = {})
        @config = SS.config.voice['lame'].merge(config)
      end

      def convert(input_file, output_file)
        bin_path = resolve_path(@config['bin'])
        opts = @config['opts']
        input_file = resolve_path(input_file)
        output_file = resolve_path(output_file)

        raise WavToMp3Error, I18n.t("voice.synthesis_fail.no_lame") unless ::File.exists?(bin_path)
        cmd = %("#{bin_path}" #{opts} "#{input_file}" "#{output_file}")

        # execute command
        Rails.logger.debug("system: #{cmd}")
        require "open3"
        stdout, stderr, status = Open3.capture3(cmd)
        Rails.logger.debug("[lame stdout] #{stdout}") if stdout.present?
        Rails.logger.info("[lame stderr] #{stderr}") if stderr.present?
        raise WavToMp3Error, I18n.t("voice.synthesis_fail.lame") unless status.exitstatus == 0
      end

    private
      def resolve_path(path)
        path = path.path if path.class.method_defined?(:path)
        path = File.join(Rails.root, path) if Pathname.new(path).relative?
        return path
      end
  end
end
