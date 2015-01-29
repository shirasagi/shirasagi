require 'pathname'
require 'voice/voice_synthesis_error'

class Voice::OpenJtalk
  DEFAULT_MAX_LENGTH = 1024

  def initialize(config = {})
    @config = SS.config.voice['openjtalk'].merge(config)
    @max_length = @config['max_length'] || DEFAULT_MAX_LENGTH
    @openjtalk_bin = resolve_path(@config['bin'])
    @openjtalk_voice = resolve_path(@config['voice'])
    @openjtalk_dic = resolve_path(@config['dic'])
    @openjtalk_opts = @config['opts']
    @sox_path = resolve_path(@config['sox'])

    raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.no_open_jtalk") unless ::File.exists?(@openjtalk_bin)
    raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.no_open_jtalk") unless ::File.exists?(@openjtalk_voice)
    raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.no_open_jtalk") unless ::File.exists?(@openjtalk_dic)
    raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.no_sox") unless ::File.exists?(@sox_path)
  end

  def build(site_id, texts, output)
    Dir.mktmpdir do |tmpdir|
      reconstructor = Voice::JapaneseTextReconstructor.new(texts, @max_length)
      intermediates = []
      reconstructor.each do |text|
        intermediates << synthesize(tmpdir, site_id, text)
      end
      join_wav(tmpdir, intermediates, output)
    end
    true
  end

  private
    def synthesize(tmpdir, site_id, text)
      tmp_source = build_source(tmpdir, site_id, text)
      tmp_output = ::File.join(tmpdir, ::Dir::Tmpname.make_tmpname(['talk', '.wav'], nil))

      run_openjtalk(tmp_source, tmp_output)
      tmp_output
    end

    def build_source(tmpdir, site_id, text)
      tmp_source = ::File.join(tmpdir, ::Dir::Tmpname.make_tmpname(['talk', '.txt'], nil))
      File.open(tmp_source, "w", encoding: Encoding::UTF_8) do |source|
        Voice::MecabParser.new(site_id, text).each do |start_pos, end_pos, hyoki, yomi|
          yomi = yomi.nil? ? hyoki : yomi
          source.write yomi.tr("ァ-ン", "ぁ-ん")
        end

        # output line break
        source.puts ''
      end
      tmp_source
    end

    def run_openjtalk(input, output)
      cmd = %("#{@openjtalk_bin}")
      cmd << %( -m "#{@openjtalk_voice}")
      cmd << %( -x "#{@openjtalk_dic}")
      cmd << %( -ow "#{output}")
      cmd << " #{@openjtalk_opts}" if @openjtalk_opts.present?
      cmd << %( "#{input}")

      Rails.logger.debug("system: #{cmd}")
      require "open3"
      stdout, stderr, status = Open3.capture3(cmd)
      Rails.logger.debug("[openjtalk stdout] #{stdout}") if stdout.present?
      Rails.logger.info("[openjtalk stderr] #{stderr}") if stderr.present?

      raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.open_jtalk") unless status.exitstatus == 0
      raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.open_jtalk") unless ::File.exists?(output)
      raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.open_jtalk") if ::File.size(output) == 0
    end

    def join_wav(tmpdir, sources, output)
      raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.empty_source") if sources.length == 0

      if sources.length == 1
        source = sources[0]
        ::FileUtils.copy(source, output)
        return true
      end

      # run sox
      tmp_output = ::File.join(tmpdir, ::Dir::Tmpname.make_tmpname(['talk', '.wav'], nil))
      source_list = sources.map{|i| %("#{i}")}.join(" ")
      cmd = %("#{@sox_path}" #{source_list} "#{tmp_output}")
      Rails.logger.debug("system: #{cmd}")
      require "open3"
      stdout, stderr, status = Open3.capture3(cmd)
      Rails.logger.debug("[sox stdout] #{stdout}") if stdout.present?
      Rails.logger.info("[sox stderr] #{stderr}") if stderr.present?

      raise Voice::VoiceSynthesisError, I18n.t("voice.synthesis_fail.sox") unless status.exitstatus == 0

      ::FileUtils.copy(tmp_output, output)
      true
    end

    def resolve_path(path)
      path = path.path if path.respond_to?(:path)
      path = File.join(Rails.root, path) if Pathname.new(path).relative?
      path
    end
end
