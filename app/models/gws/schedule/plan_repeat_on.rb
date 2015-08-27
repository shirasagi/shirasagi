class Gws::Schedule::PlanRepeatOn
  include Mongoid::Document

  field :sunday, type: Boolean
  field :monday, type: Boolean
  field :tuesday, type: Boolean
  field :wednesday, type: Boolean
  field :thursday, type: Boolean
  field :friday, type: Boolean
  field :saturday, type: Boolean

  embedded_in :plan_repeat, inverse_of: :repeat_on
end
