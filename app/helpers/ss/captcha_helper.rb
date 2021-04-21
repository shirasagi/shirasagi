module SS::CaptchaHelper
  def show_captcha
    h = []
    h << '<div class="simple-captcha">'
    h << '  <div class="image">'
    h << "    <img src=\"data:image/jpeg;base64,#{@image_path}\">"
    h << '  </div>'
    h << '  <div class="field">'
    h << '     <input type="text" name="answer[captcha_answer]" id="answer_captcha_answer">'
    h << '  </div>'
    h << '  <div class="captcha-label">'
    h << "    #{t "simple_captcha.label"}"
    h << '  </div>'
    h << '</div>'
    h.join("\n").html_safe
  end
end
