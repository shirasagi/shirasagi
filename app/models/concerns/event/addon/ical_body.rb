module Event::Addon
  module IcalBody
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :ical_link, type: String
      field :ical_description, type: String
      permit_params :ical_link, :ical_description
    end

    module ClassMethods
      def limit_docs(site, node, max)
        return if max.blank? || max <= 0

        criteria = self.site(site).node(node)
        count = criteria.count
        if count > max
          limit = count - max
          criteria.order(released: 1, _id: 1).limit(limit).each do |item|
            item.with(mongo_client_options) do |model|
              model.destroy
            end
            yield item if block_given?
          end
        end
      end
    end

    def url
      ical_link || super
    end

    def full_url
      ical_link || super
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
