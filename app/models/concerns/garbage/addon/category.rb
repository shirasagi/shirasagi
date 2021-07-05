module Garbage::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :categories, class_name: "Garbage::Node::Category"
      permit_params category_ids: []

      template_variable_handler(:categories, :template_variable_handler_categories)

      liquidize do
        export as: :categories do
          categories.and_public.order_by(order: 1, name: 1)
        end
      end
    end

    def template_variable_handler_categories(name, issuer)
      ERB::Util.html_escape self.categories.map(&:name).join("\n")
    end
  end
end
