module Rss::Addon::Page
  module Body
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :rss_link, type: String
      field :html, type: String
      embeds_many :authors, class_name: "Rss::Author", as: :rss_author
      permit_params :rss_link, :html

      validates :rss_link, presence: true, url: { absolute_path: true }
      validate :encode_rss_link
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

    def effective_rss_link
      return rss_link if rss_link.blank?
      return unless UrlValidator.valid?(rss_link, absolute_path: true)
      SS.follow_up_url_encode!(rss_link) rescue nil
    end

    def url
      ret = effective_rss_link rescue nil
      ret.presence || super
    end

    def full_url
      ret = effective_rss_link rescue nil
      ret.presence || super
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

    private

    def encode_rss_link
      return unless rss_link_changed?
      return if errors[:rss_link].present?
      self.rss_link = SS.follow_up_url_encode!(rss_link)
    rescue => e
      Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      errors.add :rss_link, :url
    end
  end
end
