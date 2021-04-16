module SS::CaptchaFilter
  extend ActiveSupport::Concern

  included do
    helper SS::CaptchaHelper
  end

  def generate_captcha
    MiniMagick::Tool::Convert.new do |convert|
      @captcha_text = sprintf("%04d", rand(10000))
      convert.size "100x28"
      convert.background "white"
      convert.fill "darkblue"
      convert.wave "1x88"
      convert.implode "0.2"
      convert.pointsize "22"
      convert.gravity "Center"
      convert.implode "0.2"
      convert << "label:#{@captcha_text}"
      convert << "tmp/captcha.jpeg"
    end

    generate_key
    generate_image_path
    create_captcha_data
  end

  def generate_key
    random_key = (Time.now.to_f * 1_000_000_000).to_s
    session[:captcha_key] = Digest::SHA1.hexdigest(random_key)
  end

  def generate_image_path
    session[:image_path] = `base64 tmp/captcha.jpeg`
  end

  def create_captcha_data
    SS::CaptchaBase::Captcha.create(captcha_key: session[:captcha_key], captcha_text: @captcha_text)
  end

  def render_pre_page?(obj, render_opt)
    rendered = false

    obj.captcha_answer = params[:answer].try(:[], :captcha_answer)
    obj.captcha_text = SS::CaptchaBase::Captcha.find_by(captcha_key: session[:captcha_key]).captcha_text

    unless obj.valid_with_captcha?
      generate_captcha
      render render_opt
      rendered = true
    end

    rendered
  end
end
