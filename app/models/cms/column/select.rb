class Cms::Column::Select < Cms::Column::Base
  include Cms::Addon::Column::SelectLike

  field :place_holder, type: String
end
