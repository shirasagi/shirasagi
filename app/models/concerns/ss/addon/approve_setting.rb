module SS::Addon::ApproveSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :forced_update, type: String
    field :close_confirmation, type: String
    validates :forced_update, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :close_confirmation, inclusion: { in: %w(enabled disabled), allow_blank: true }
    permit_params :forced_update, :close_confirmation
  end

  def forced_update_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def close_confirmation_options
    %w(enabled disabled).map do |v|
      [I18n.t("ss.options.state.#{v}"), v]
    end
  end

  def close_confirmation_enabled?
    close_confirmation == 'enabled' || close_confirmation.blank?
  end
end
