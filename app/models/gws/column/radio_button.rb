class Gws::Column::RadioButton < Gws::Column::Base
  include Gws::Addon::Column::SelectLike

  field :branch_section_ids, type: Array, default: []
  field :other_state, type: String, default: 'disabled'
  field :other_required, type: String, default: 'optional'
  permit_params :other_state, :other_required
  permit_params branch_section_ids: []

  def other_state_options
    %w(enabled disabled).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def other_required_options
    %w(required optional).map { |k| [I18n.t("ss.options.state.#{k}"), k] }
  end

  def other_required?
    other_required == 'required'
  end

  def branch_section_options
    form.columns.where(_type: Gws::Column::Section.to_s).order_by(order: 1).map do |c|
      [I18n.t('gws/column.show_section', name: c.name), c.id]
    end
  end

  def branch_section_id(index)
    return 'none' if branch_section_ids[index] == ''
    return branch_section_ids[index] if branch_section_ids[index]
    nil
  end

  def serialize_value(value, values = {})
    Gws::Column::Value::RadioButton.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value, other_value: values[:other_value]
    )
  end
end
