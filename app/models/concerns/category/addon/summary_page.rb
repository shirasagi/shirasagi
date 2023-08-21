module Category::Addon
  module SummaryPage
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      belongs_to :summary_page, class_name: "Cms::Page"
      permit_params :summary_page_id
      liquidize do
        export :summary_page
      end
    end
  end
end
