module SS::Captchable
  extend ActiveSupport::Concern

  included do
    attr_accessor :captcha_answer, :captcha_text, :captcha_error

    permit_params :captcha_answer, :captcha_text, :captcha_error
  end

  def valid_with_captcha?
    [valid?, captcha_valid?].all?
  end

  def captcha_valid?
    if captcha_answer == captcha_text && captcha_text.present?
      return true
    else
      message = I18n.t(self.class.model_name.to_s.downcase, :scope => [:simple_captcha, :message], :default => :default)
      errors.add(:captcha, message)
      return false
    end
  end
end
