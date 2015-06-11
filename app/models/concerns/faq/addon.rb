module Faq::Addon
  module Question
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :question, type: String, metadata: { form: :text }
      permit_params :question
    end
  end

  module Search
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 500

    included do
      belongs_to :search_node, class_name: "Faq::Node::Search"
      permit_params :search_node_id
    end
  end

end
