module ImageMap::Addon
  module ImageSetting
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      belongs_to_file :image, presence: true
      field :area_states, type: Array, default: []
      field :supplement_state, type: String, default: "disabled"

      permit_params area_states: [:name, :value]
      permit_params :supplement_state

      validate :validate_area_states
    end

    def area_state_options
      area_states.map { |state| [state["name"], state["value"]] }
    end

    def supplement_state_options
      [
        [I18n.t("ss.options.state.enabled"), "enabled"],
        [I18n.t("ss.options.state.disabled"), "disabled"],
      ]
    end

    def supplement_enabled?
      area_state_options.present? && supplement_state == "enabled"
    end

    private

    def validate_area_states
      return if area_states.blank?
      self.area_states = area_states.select do |item|
        item["name"].present? && item["value"].present?
      end
    end
  end
end
