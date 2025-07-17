class Cms::Column::CheckBox < Cms::Column::Base
  include Cms::Addon::Column::SelectLike

  def db_form_type
    { type: 'textarea', rows: 4 }
  end

  def exact_match_to_value(value, opts = {})
    case opts[:operator]
    when 'any_of'
      { values: /#{::Regexp.escape(value)}/ }
    when 'start_with'
      { values: /\A#{::Regexp.escape(value)}/ }
    when 'end_with'
      { values: /#{::Regexp.escape(value)}\z/ }
    else
      { values: value }
    end
  end
end
