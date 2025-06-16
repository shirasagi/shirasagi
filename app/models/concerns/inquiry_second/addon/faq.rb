module Inquiry::Addon
  module Faq
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      belongs_to :faq, class_name: 'Faq::Node::Page'
      permit_params :faq_id
    end
  end
end
