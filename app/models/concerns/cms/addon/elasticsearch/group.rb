module Cms::Addon::Elasticsearch
  module Group
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :elasticsearch_state, type: String
      permit_params :elasticsearch_state

      # scope :and_elasticsearch_enabled -> {
      #   self.and("$or" => [{ elasticsearch_state: nil }, { elasticsearch_state: 'enabled' }])
      # }
      # scope :and_elasticsearch_disabled, -> {
      #   self.and(elasticsearch_state: 'disabled')
      # }
    end

    def elasticsearch_state_options
      %w(enabled disabled).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
    end

    # def elasticsearch_enabled?
    #   elasticsearch_state != 'disabled'
    # end
  end
end
