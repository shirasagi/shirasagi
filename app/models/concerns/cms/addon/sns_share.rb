module Cms::Addon
  module SnsShare
    extend ActiveSupport::Concern
    extend SS::Addon

    SERVICES = %w(fb_like fb_share twitter hatena google evernote).freeze

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
        [I18n.t('views.options.state.show'), 'show'],
        [I18n.t('views.options.state.hide'), 'hide'],
      ]
    end

    def sns_share_state(name)
      sns_share_states.try(:[], name)
    end

    def sns_share_order(name)
      sns_share_orders.try(:[], name)
    end

    def sns_share_state_label(name)
      value = sns_share_state(name) != 'hide' ? 'show' : 'hide'
      I18n.t("views.options.state.#{value}")
    end

    def sort_sns_share_services
      list = sns_share_services
      list = sns_share_orders.sort_by { |name, order| order } if sns_share_orders.present?
      list = list.select do |name, _|
        sns_share_state(name) != "hide"
      end
      list.map { |name, order| name }
    end
  end
end
