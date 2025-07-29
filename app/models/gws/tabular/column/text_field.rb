class Gws::Tabular::Column::TextField < Gws::Column::Base
  include Gws::Tabular::Column::TextLike
  include Gws::Addon::Tabular::Column::TextField
  include Gws::Addon::Tabular::Column::Base
end
