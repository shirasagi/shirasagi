module Category::Addon
  module CategoryList
    extend ActiveSupport::Concern
    extend SS::Addon
    include ::Category::TemplateVariable

    included do
      field :category_limit, type: Integer, default: 5
      field :category_loop_html, type: String
      field :category_upper_html, type: String
      field :category_lower_html, type: String
      permit_params :category_conditions, :category_limit, :category_loop_html
      permit_params :category_upper_html, :category_lower_html
    end
  end
end
