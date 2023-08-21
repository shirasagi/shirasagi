module Gws::Addon::System::FileSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

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
end
