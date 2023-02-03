module ImageMap::Addon
  module ImageSetting
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      belongs_to_file :image, presence: true
      field :area_states, type: Array, default: []

      permit_params area_states: [:name, :value]

      validate :validate_area_states
    end

    def area_state_options
      area_states.map { |state| [state["name"], state["value"]] }
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
