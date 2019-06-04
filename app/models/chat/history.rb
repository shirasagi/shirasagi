class Chat::History
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Cms::Addon::GroupPermission

  set_permission_name 'chat_bots'

  index({ created: -1, id: -1 })

  seqid :id
  field :session_id, type: String
  field :request_id, type: String
  field :text, type: String
  field :result, type: String
  field :suggest, type: SS::Extensions::Words

  belongs_to :node, class_name: "Chat::Node::Bot", inverse_of: :histories
  belongs_to :prev_intent, class_name: "Chat::Intent"
  belongs_to :intent, class_name: "Chat::Intent"

  permit_params :text

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :session_id, :request_id, :text, :result, :suggest
      end
      criteria
    end
  end
end
