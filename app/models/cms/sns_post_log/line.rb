class Cms::SnsPostLog::Line < Cms::SnsPostLog::Base
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Site

  field :messages, type: Array, default: []
  field :response_code, type: String
  field :response_body, type: String

  def type
    "line"
  end
end
