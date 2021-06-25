class Cms::SnsPostLog::Twitter < Cms::SnsPostLog::Base
  extend SS::Translation
  include SS::Document
  include Cms::Reference::Site

  field :message, type: String
  field :media_files, type: Array, default: []
  field :destroy_post_ids, type: Array, default: []
  field :response_tweet, type: String

  def type
    "twitter"
  end
end
