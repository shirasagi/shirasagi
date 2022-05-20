class Cms::SnsPostLog::Line < Cms::SnsPostLog::Base
  field :messages, type: Array, default: []
  field :multicast_user_ids, type: Array, default: []
  field :response_code, type: String
  field :response_body, type: String

  def type
    "line"
  end
end
