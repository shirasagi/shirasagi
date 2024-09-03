module Gws::Addon::Workflow2::DestinationState
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :destination_treat_state, type: String

    validates :destination_treat_state, presence: true
    validates :destination_treat_state, inclusion: { in: %w(untreated treated no_need_to_treat), allow_blank: true }
  end

  module ClassMethods
    def search_destination_treat_state(params)
      return all if params[:destination_treat_state].blank?

      case params[:destination_treat_state]
      when "treated"
        all.in(destination_treat_state: %w(treated no_need_to_treat))
      when "untreated"
        all.where(destination_treat_state: "untreated")
      else
        none
      end
    end
  end

  def destination_treat_state_options
    %w(untreated treated no_need_to_treat).map do |v|
      [ I18n.t("gws/workflow.options.destination_treat_state.#{v}"), v ]
    end
  end
end
