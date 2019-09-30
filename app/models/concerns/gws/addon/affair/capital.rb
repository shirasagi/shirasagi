module Gws::Addon::Affair::Capital
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :capital, class_name: "Gws::Affair::Capital"
    field :capital_state, type: String, default: "normal"
    field :capital_basic_code, type: String
    field :capital_project_code, type: String
    field :capital_detail_code, type: String

    permit_params :capital_id
    permit_params :capital_state

    before_validation :set_capital_code, if: -> { capital }
    validates :capital_id, presence: true
  end

  def capital_emergency?
    capital_state == "emergency"
  end

  private

  def set_capital_code
    self.capital_basic_code = capital.basic_code
    self.capital_project_code = capital.project_code.to_s
    self.capital_detail_code = capital.detail_code.to_s
  end
end
