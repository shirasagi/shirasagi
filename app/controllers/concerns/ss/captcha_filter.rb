module SS::CaptchaFilter
  extend ActiveSupport::Concern

  included do
    helper SS::CaptchaHelper
  end

  def generate_captcha
    Dir.mktmpdir do |dir|
      MiniMagick::Tool::Convert.new do |convert|
        @captcha_text = sprintf("%04d", rand(10_000))
        convert.size "100x28"
        convert.background "white"
        convert.fill "darkblue"
        convert.wave "1x88"
        convert.implode "0.2"
        convert.pointsize "22"
        convert.gravity "Center"
        convert.implode "0.2"
        convert << "label:#{@captcha_text}"
        convert << "#{dir}/captcha.jpeg"
      end

      generate_image_path("#{dir}/captcha.jpeg")
    end

    create_captcha_data
  end

  def generate_image_path(tmp_dir_captcha)
    binary_data = File.binread(tmp_dir_captcha)
    @image_path = Base64.strict_encode64(binary_data)
  end

  def create_captcha_data
    captcha = SS::Captcha.create(captcha_text: @captcha_text, image_path: @image_path)
    session[:captcha_id] = captcha.id
  end

  def get_captcha
    captcha = {}
    captcha[:captcha_answer] = params[:answer].try(:[], :captcha_answer)
    captcha[:captcha_text] = SS::Captcha.find(session[:captcha_id]).captcha_text

    captcha
  end

  def render_pre_page?(obj, render_opt, rendered)
    obj.attributes = get_captcha

    unless obj.valid_with_captcha?
      generate_captcha
      render render_opt
      rendered = true
    end

    rendered
  end
end
