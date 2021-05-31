class SS::Captcha
  include SS::Document

  field :captcha_text, type: String
  field :captcha_error, type: String

  attr_accessor(:image_path)

  index({ created: 1 }, { expire_after_seconds: 3600 })

  class << self
    def generate_captcha
      Dir.mktmpdir do |dir|
        captcha_text = sprintf("%04d", rand(10_000))
        MiniMagick::Tool::Convert.new do |convert|
          convert.size "100x28"
          convert.background "white"
          convert.fill "darkblue"
          convert.wave "1x88"
          convert.implode "0.2"
          convert.pointsize "22"
          convert.gravity "Center"
          convert << "label:#{captcha_text}"
          convert << "#{dir}/captcha.jpeg"
        end

        create_captcha_data(captcha_text, "#{dir}/captcha.jpeg", nil)
      end
    #rescue => e
    #  Rails.logger.fatal("generate_captcha failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    #  create_captcha_data(nil, nil, e)
    end

    def create_captcha_data(captcha_text, tmp_dir_captcha, exception)
      if tmp_dir_captcha.present?
        binary_data = File.binread(tmp_dir_captcha)
        image_path = Base64.strict_encode64(binary_data)
      end

      cur_captcha = SS::Captcha.create(
        captcha_text: captcha_text, captcha_error: "#{exception.try(:class)}#{exception.try(:message)}"
      )
      cur_captcha.image_path = image_path

      cur_captcha
    end
  end
end
