module Ezine::Entryable
  extend ActiveSupport::Concern

  included do
    include Mongoid::Document

    field :email,              type: String
    field :email_type,         type: String
    field :entry_type,         type: String
    field :verification_token, type: String

    belongs_to :node, class_name: "Cms::Node"

    scope :verified, ->{ where verification_token: nil }
  end
end
