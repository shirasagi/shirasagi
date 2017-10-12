module Gws::File::GroupSetting
  extend ActiveSupport::Concern
  extend Gws::GroupSetting

  included do
    field :multibyte_filename_state, type: String
    validates :multibyte_filename_state, inclusion: { in: %w(enabled disabled), allow_blank: true }
    permit_params :multibyte_filename_state
  end

  def multibyte_filename_state_options
    %w(enabled disabled).map { |m| [ I18n.t("ss.options.multibyte_filename_state.#{m}"), m ] }.to_a
  end

  def multibyte_filename_disabled?
    multibyte_filename_state == 'disabled'
  end

  def multibyte_filename_enabled?
    !multibyte_filename_disabled?
  end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::File::Setting.allowed?(action, user, opts)
      # super
      false
    end
  end
end
