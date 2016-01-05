module Ckan::Addon
  module Status
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :ckan_url, type: String
      field :ckan_status, type: String
      permit_params :ckan_url, :ckan_status
    end

    public
      def ckan_status_options
        %w(dataset tag group related_item).map { |m| [ I18n.t("ckan.options.ckan_status.#{m}"), m ] }.to_a
      end
  end
end
