module Category::Addon
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      liquidize do
        export :summarized_categories
      end
      before_save :set_category_map_icon
    end

    def summarized_categories
      ::Category::Node::Base.site(site).where(summary_page_id: id).to_a
    end

    def set_category_map_icon
      return if !respond_to?(:map_points)
      return if map_points.blank?

      category = categories.order_by(order: 1).to_a.
        select { |cate| cate.map_icon_url.present? }.first
      return if category.nil?

      uri = ::Addressable::URI.parse(category.map_icon_url) rescue nil
      return if uri.nil?

      if uri.host.present?
        map_icon_url = uri.to_s
      else
        map_icon_url = ::File.join((cur_site || site).full_url, uri.path)
      end

      self.map_points.each do |point|
        point["image"] = map_icon_url
      end
    end
  end
end
