class Cms::Column::Select < Cms::Column::Base
  include Cms::Addon::Column::SelectLike

  self.use_parent_column_name = true

  field :place_holder, type: String
end
