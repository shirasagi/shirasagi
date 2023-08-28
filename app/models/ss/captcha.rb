class SS::Captcha
  include SS::Document

  attr_accessor :out_captcha_image_base64

  field :captcha_text, type: String
  field :captcha_error, type: String

  store_in_repl_master

  index({ created: 1 }, { expire_after_seconds: 3600 })

  class << self
    def generate_captcha
      Dir.mktmpdir do |dir|
        captcha_text = format("%04d", rand(10_000))
        captcha_image_path = "#{dir}/captcha.jpeg"

        MiniMagick::Tool::Convert.new do |convert|
          convert.size SS.config.cms.captcha["image_size"]
          convert.background SS.config.cms.captcha["background"]
          convert.fill SS.config.cms.captcha["fill"]
          convert.wave SS.config.cms.captcha["wave"]
          if SS.config.cms.captcha["font"].present?
            convert.font SS.config.cms.captcha["font"]
          end
          convert.implode SS.config.cms.captcha["implode"]
          convert.pointsize SS.config.cms.captcha["pointsize"]
          convert.gravity SS.config.cms.captcha["gravity"]
          convert << "label:#{captcha_text}"
          convert << captcha_image_path
        end

        create_captcha_data(captcha_text, captcha_image_path)
      end
    rescue => e
      Rails.logger.fatal("generate_captcha failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      create_captcha_error(e)
    end

    def create_captcha_data(captcha_text, captcha_image_path)
      captcha_image_bin = File.binread(captcha_image_path)
      captcha_image_base64 = Base64.strict_encode64(captcha_image_bin)

      SS::Captcha.create(captcha_text: captcha_text, out_captcha_image_base64: captcha_image_base64)
    end

    def create_captcha_error(exception)
      captcha_error = "#{exception.try(:class)}#{exception.try(:message)}"
      SS::Captcha.create(captcha_error: captcha_error)
    end
  end
end
