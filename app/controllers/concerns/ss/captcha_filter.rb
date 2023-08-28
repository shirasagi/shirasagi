module SS::CaptchaFilter
  extend ActiveSupport::Concern

  included do
    helper_method :show_captcha
  end

  def show_captcha(show_specific_error: false)
    @cur_captcha = SS::Captcha.generate_captcha
    session[:captcha_id] = @cur_captcha.id

    if @cur_captcha.captcha_error.blank?
      h = []
      h << '<div class="simple-captcha">'
      h << '  <div class="image">'
      h << "    <img src=\"data:image/jpeg;base64,#{@cur_captcha.out_captcha_image_base64}\">"
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

    if show_specific_error
      h = []
      h << "<p>#{t "simple_captcha.captcha_error"}</p>"
      h << "<p>#{@cur_captcha.captcha_error}</p>"

      return h.join("\n").html_safe
    else
      return "<p>#{t "simple_captcha.captcha_error"}</p>".html_safe
    end

    return
  end

  def captcha_answer
    params[:answer].try(:[], :captcha_answer)
  end

  def captcha_valid?(item, answer = nil)
    captcha_id = session.delete(:captcha_id)
    unless captcha_id
      message = I18n.t(item.class.model_name.to_s.downcase, :scope => [:simple_captcha, :message], :default => :default)
      item.errors.add :captcha, message
      return false
    end

    captcha = SS::Captcha.find(captcha_id) rescue nil
    if captcha.blank? || captcha.captcha_text.blank? || captcha.captcha_error.present?
      message = I18n.t(item.class.model_name.to_s.downcase, :scope => [:simple_captcha, :message], :default => :default)
      item.errors.add :captcha, message
      return false
    end

    answer ||= captcha_answer
    if answer.blank?
      message = I18n.t(item.class.model_name.to_s.downcase, :scope => [:simple_captcha, :message], :default => :default)
      item.errors.add :captcha, message
      return false
    end

    if answer != captcha.captcha_text
      message = I18n.t(item.class.model_name.to_s.downcase, :scope => [:simple_captcha, :message], :default => :default)
      item.errors.add :captcha, message
      return false
    end

    return true
  end
end
