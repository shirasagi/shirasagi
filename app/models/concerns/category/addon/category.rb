module Category::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      liquidize do
        export :summarized_categories
      end
    end

    def summarized_categories
      ::Category::Node::Base.site(site).where(summary_page_id: id).to_a
    end
  end
end
