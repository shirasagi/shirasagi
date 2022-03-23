module Cms::Addon
  module Line::Service::Chat
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      belongs_to :node, class_name: "Chat::Node::Bot"
      permit_params :node_id
      validates :node_id, presence: true
    end
  end
end
