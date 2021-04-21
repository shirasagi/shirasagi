module SS::CaptchaFilter
  extend ActiveSupport::Concern

  included do
    helper SS::CaptchaHelper
  end

  def generate_captcha
    delete_tmp_dir
    session[:tmp_dir] = Dir.mktmpdir

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
      convert << "#{session[:tmp_dir]}/captcha.jpeg"

      @tmp_dir_captcha = "#{session[:tmp_dir]}/captcha.jpeg"
    end

    generate_key
    generate_image_path
    create_captcha_data
  end

  def generate_key
    session[:captcha_key] = sprintf("%05d", rand(100000))
  end

  def generate_image_path
    binary_data = File.read(@tmp_dir_captcha)
    @image_path = Base64.strict_encode64(binary_data)
  end

  def create_captcha_data
    SS::Captcha.create(captcha_key: session[:captcha_key], captcha_text: @captcha_text)
  end

  def get_captcha
    captcha = {}
    captcha[:captcha_answer] = params[:answer].try(:[], :captcha_answer)
    captcha[:captcha_text] = SS::Captcha.find_by(captcha_key: session[:captcha_key]).captcha_text

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

  def delete_tmp_dir
    FileUtils.remove_entry_secure session[:tmp_dir] rescue nil
  end
end
