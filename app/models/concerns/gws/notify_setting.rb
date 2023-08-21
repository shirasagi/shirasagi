module Gws::NotifySetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    class_variable_set(:@@_notify_state_default, 'disabled')

    field :notify_state, type: String, default: ->{ notify_state_default }
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

  def notify_state_default
    self.class.class_variable_get(:@@_notify_state_default)
  end
end
