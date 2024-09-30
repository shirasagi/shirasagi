module Gws::NotifySetting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :notify_state, type: String, default: ->{ self.class.default_notify_state }
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

  module ClassMethods
    def default_notify_state
      models = SS.config.gws.notify_setting["notify_enabled_models"].to_a rescue []
      models.include?(name) ? "enabled" : 'disabled'
    end
  end
end
