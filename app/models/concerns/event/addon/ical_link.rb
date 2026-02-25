module Event::Addon
  module IcalLink
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :ical_uid, type: String
      field :ical_link, type: String
      permit_params :ical_uid, :ical_link
    end

    module ClassMethods
      def limit_docs(site, node, max)
        return if max.blank? || max <= 0

        criteria = self.site(site).node(node)
        count = criteria.count
        if count > max
          limit = count - max
          criteria.order('event_dates.0' => 1, _id: 1).limit(limit).each do |item|
            item.with(mongo_client_options) do |model|
              model.destroy
            end
            yield item if block_given?
          end
        end
      end
    end

    def url
      ret = ical_link rescue nil
      ret.presence || super
    end

    def full_url
      ret = ical_link rescue nil
      ret.presence || super
    end

    def json_path
      ret = ical_link rescue nil
      ret.present? ? nil : super
    end

    def json_url
      ret = ical_link rescue nil
      ret.present? ? nil : super
    end
  end
end
