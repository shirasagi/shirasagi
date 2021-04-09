module SS::CaptchaHelper
  def show_captcha(f)
    render(partial: 'captcha/captcha.erb', locals: {f: f})
  end

  def captcha_options(option, f)
    if option == "image"
      @option = "image"
    elsif option == "field"
      @option = "field"
    elsif option == "label"
      @option = "label"
    end

    render(partial: 'captcha/option.erb', locals: {f: f})
  end
end
