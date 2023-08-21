module Rss::Addon::Page
  module Body
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :rss_link, type: String
      field :html, type: String
      embeds_many :authors, class_name: "Rss::Author", as: :rss_author
      permit_params :rss_link, :html

      validates :rss_link, presence: true
    end

    module ClassMethods
      def limit_docs(site, node, max)
        return if max.blank? || max <= 0

        criteria = self.site(site).node(node)
        count = criteria.count
        if count > max
          limit = count - max
          criteria.reorder(released: 1, id: 1).limit(limit).each do |item|
            item.with(mongo_client_options) do |model|
              model.destroy
            end
            yield item if block_given?
          end
        end
      end
    end

    def url
      rss_link.presence || super
    end

    def full_url
      rss_link.presence || super
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
