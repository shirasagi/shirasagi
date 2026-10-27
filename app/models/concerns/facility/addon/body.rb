module Facility::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kana, type: String
      field :postcode, type: String
      field :address, type: String
      field :tel, type: String
      field :fax, type: String
      field :related_url, type: String

      permit_params :kana, :postcode, :address, :tel, :fax, :related_url

      validates :related_url, url: { absolute_path: true, allow_blank: true }
      validate :encode_related_url
    end

    private

    def encode_related_url
      return if errors[:related_url].present?
      return unless related_url_changed?
      self.related_url = SS.follow_up_url_encode!(related_url)
    rescue => e
      Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      errors.add :related_url, :url
    end
  end
end
