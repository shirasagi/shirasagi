class SS::Captcha
  include SS::Document

  seqid :id
  field :captcha_key, type: String
  field :captcha_text, type: String

  index({ created: 1 }, { expire_after_seconds: 3600 })
end
