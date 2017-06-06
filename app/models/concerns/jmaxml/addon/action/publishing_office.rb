module Jmaxml::Addon::Action::PublishingOffice
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :publishing_office_state, type: String
    permit_params :publishing_office_state
  end

  def publishing_office_state_options
    %w(hide show).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end
end
