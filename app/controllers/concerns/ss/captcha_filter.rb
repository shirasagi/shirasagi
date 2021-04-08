module SS::CaptchaFilter
  extend ActiveSupport::Concern

  def generate_image
    @captcha_image = MiniMagick::Tool::Convert.new do |convert|
      text = sprintf("%04d", rand(10000))
      convert.size "100x28"
      convert.background "white"
      convert.fill "darkblue"
      convert.wave "0x88"
      convert.implode "0.2"
      convert.pointsize "22"
      convert.gravity "Center"
      convert.implode "0.2"
      convert << "label:#{text}"
      convert << "app/assets/images/captcha.jpeg"
    end
  end
end
