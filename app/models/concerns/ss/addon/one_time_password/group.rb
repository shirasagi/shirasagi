module SS::Addon::OneTimePassword::Group
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :otpw_state, type: String
    field :otpw_whitelist, type: SS::Extensions::Lines

    permit_params :otpw_state, :otpw_whitelist

    validates :otpw_state, inclusion: { in: %w(enabled disabled) }, if: ->{ otpw_state.present? }
  end

  def otpw_state_options
    %w(enabled disabled).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def otpw_whitelist_request?(remote_addr)
    otpw_whitelist.any? do |value|
      IPAddr.new(value).include?(remote_addr) rescue false
    end
  end
end
