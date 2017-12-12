module Gws::Addon::Discussion::NotifySetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :notify_state, type: String, default: 'disabled'
    permit_params :notify_state
  end

  def notify_state_options
    %w(enabled disabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def notify_enabled?
    notify_state == 'enabled'
  end
end
