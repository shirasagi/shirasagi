module Member::Addon::Registration
  module Confirmation
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :confirm_personal_data_state, type: String
      field :confirm_personal_data_html, type: String
      field :header_html, type: String
      field :footer_html, type: String
      permit_params :confirm_personal_data_state, :confirm_personal_data_html, :header_html, :footer_html
    end

    def confirm_personal_data_state_options
      %w(disabled enabled).map { |m| [ I18n.t("member.options.confirm_personal_data_state.#{m}"), m ] }.to_a
    end
  end
end
