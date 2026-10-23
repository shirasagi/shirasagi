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

      before_validation :encode_related_url
      validates :related_url, url: { absolute_path: true, allow_blank: true }
    end

    private

    def encode_related_url
      return unless related_url_changed?
      self.related_url = SS.safe_encode_url(related_url)
    end
  end
end
