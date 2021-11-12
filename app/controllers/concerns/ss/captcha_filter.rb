module SS::CaptchaFilter
  extend ActiveSupport::Concern

  included do
    helper_method :show_captcha
  end

  def show_captcha(options = {})
    @cur_captcha = SS::Captcha.generate_captcha
    session[:captcha_id] = @cur_captcha.id

    if @cur_captcha.captcha_text.present? && options.present?
      return "<img src=\"data:image/jpeg;base64,#{@cur_captcha.image_path}\">".html_safe
    elsif @cur_captcha.captcha_text.present?
      h = []
      h << '<div class="simple-captcha">'
      h << '  <div class="image">'
      h << "    <img src=\"data:image/jpeg;base64,#{@cur_captcha.image_path}\">"
      h << '  </div>'
      h << '  <div class="field">'
      h << '     <input type="text" name="answer[captcha_answer]" id="answer_captcha_answer">'
      h << '  </div>'
      h << '  <div class="captcha-label">'
      h << "    #{t "simple_captcha.label"}"
      h << '  </div>'
      h << '</div>'

      return h.join("\n").html_safe
    end

    if options.fetch(:show_specific_error, false)
      h = []
      h << "<p>#{t "simple_captcha.captcha_error"}</p>"
      h << "<p>#{@cur_captcha.captcha_error}</p>"

      return h.join("\n").html_safe
    else
      return "<p>#{t "simple_captcha.captcha_error"}</p>".html_safe
    end

    return
  end

  def get_captcha
    captcha = {}
    captcha_data = SS::Captcha.find(session[:captcha_id])
    captcha[:captcha_answer] = params[:answer].try(:[], :captcha_answer)
    captcha[:captcha_text] = captcha_data.captcha_text
    captcha[:captcha_error] = captcha_data.captcha_error

    captcha
  end

  def captcha_valid?(item)
    item.attributes = get_captcha
    return item.valid_with_captcha?
  end
end
