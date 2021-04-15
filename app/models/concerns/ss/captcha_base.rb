module SS::CaptchaBase
  extend ActiveSupport::Concern

  included do
    attr_accessor :captcha_answer, :captcha_text
    permit_params :captcha_answer, :captcha_text
  end

  def valid_with_captcha?
    [valid?, is_captcha_valid?].all?
  end

  def is_captcha_valid?
    if captcha_answer == captcha_text
      return true
    else
      message = I18n.t(self.class.model_name.to_s.downcase, :scope => [:simple_captcha, :message], :default => :default)
      errors.add(:captcha, message)
      return false
    end
  end

  class Captcha
    include SS::Document

    seqid :id
    field :captcha_key, type: String
    field :captcha_text, type: String

    index({ created: 1 }, { expire_after_seconds: 3600 })
  end
end
