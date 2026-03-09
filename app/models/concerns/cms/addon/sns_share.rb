module Cms::Addon
  module SnsShare
    extend ActiveSupport::Concern
    extend SS::Addon

    SERVICES = %w(fb_share twitter hatena line).freeze

    included do
      field :sns_share_states, type: Hash
      field :sns_share_orders, type: Hash
      permit_params sns_share_states: SERVICES, sns_share_orders: SERVICES
    end

    def sns_share_services
      SERVICES
    end

    def sns_share_states_options
      [
        [I18n.t('cms.options.sns_share_state.show'), 'show'],
        [I18n.t('cms.options.sns_share_state.link_only'), 'link_only'],
        [I18n.t('cms.options.sns_share_state.hide'), 'hide'],
      ]
    end

    def sns_share_state(name)
      sns_share_states.try(:[], name)
    end

    def sns_share_order(name)
      sns_share_orders.try(:[], name)
    end

    def sns_share_state_label(name)
      case sns_share_state(name)
      when 'hide'
        I18n.t("cms.options.sns_share_state.hide")
      when 'link_only'
        I18n.t("cms.options.sns_share_state.link_only")
      else # 'show'
        I18n.t("cms.options.sns_share_state.show")
      end
    end

    def sort_sns_share_services
      services = sns_share_services.map { [ _1, sns_share_state(_1) || 'show' ] }
      services.select! { |_service_name, service_type| service_type != 'hide' }
      services.sort_by! { |service_name, _service_type| sns_share_order(service_name) || 0 }
      services
    end
  end
end
