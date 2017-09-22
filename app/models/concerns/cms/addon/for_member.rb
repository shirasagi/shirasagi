module Cms::Addon
  module ForMember
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :for_member_state, type: String, default: "disabled"

      permit_params :for_member_state

      validates :for_member_state, inclusion: { in: %w(disabled enabled) }
    end

    def for_member_state_options
      %w(disabled enabled).map do |v|
        [I18n.t("ss.options.state.#{v}"), v]
      end
    end

    def for_member_enabled?
      self.for_member_state == 'enabled'
    end

    def for_member_disabled?
      !for_member_enabled?
    end
  end
end
