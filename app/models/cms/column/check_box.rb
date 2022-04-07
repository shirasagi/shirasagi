class Cms::Column::CheckBox < Cms::Column::Base
  include Cms::Addon::Column::SelectLike

  def db_form_type
    { type: 'textarea', rows: 4 }
  end

  def exact_match_to_value(value)
    { values: value }
  end
end
