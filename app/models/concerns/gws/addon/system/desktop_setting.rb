module Gws::Addon::System::DesktopSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :desktop_mailstore, type: String
    field :desktop_chat, type: String

    permit_params :desktop_mailstore, :desktop_chat
  end

  def desktop_mailstore_options
    %w(enabled disabled).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def desktop_chat_options
    %w(enabled disabled).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def desktop_settings
    {
      mailstore: desktop_mailstore || 'enabled',
      chat: desktop_chat || 'enabled'
    }
  end
end
