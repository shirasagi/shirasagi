module SS::CaptchaBase
  extend ActiveSupport::Concern

  included do
    attr_accessor :captcha_answer, :image_text
  end


  def valid_with_captcha?(captcha_answer, image_text)
    captcha_answer == image_text
  end

  def valid_with_captcha?
    [valid?, is_captcha_valid?].all?
  end

  def is_captcha_valid?
    if captcha_answer == image_text
      return true
    else
      message = I18n.t(self.class.model_name.to_s.downcase, :scope => [:simple_captcha, :message], :default => :default)
      errors.add(:captcha, message)
      return false
    end
  end

  # def validate_captcha
  #   errors.add(:captcha, I18n.t('simple_captcha.message.default')) if captcha_answer != image_text
  # end
end
