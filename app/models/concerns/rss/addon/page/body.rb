module Rss::Addon::Page
  module Body
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :rss_link, type: String
      field :html, type: String
      embeds_many :authors, class_name: "Rss::Author", as: :rss_author
      permit_params :rss_link, :html
    end

    module ClassMethods
      def limit_docs(site, node, max)
        return if max.blank? || max <= 0

        criteria = Rss::Page.site(site).node(node)
        count = criteria.count
        if count > max
          limit = count - max
          criteria.order(released: 1, _id: 1).limit(limit).each do |item|
            item.destroy
            yield item if block_given?
          end
        end
      end
    end

    def url
      rss_link
    end

    def full_url
      rss_link
    end

    def json_path
      nil
    end

    def json_url
      nil
    end

    def serve_static_file?
      false
    end
  end
end
