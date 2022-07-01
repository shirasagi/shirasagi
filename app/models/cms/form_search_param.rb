class Cms::FormSearchParam
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :cur_node, :s

  def condition_hash
    return {} if s.blank? || s[:col].blank?

    conditions = []
    s[:col].each do |key, value|
      next if key.blank? || value.blank?

      columns = find_columns(key)
      next if columns.blank?

      conditions << build_column_condition(columns, value)
    end
    return {} if conditions.blank?
    return conditions.first if conditions.length == 1

    { "$and" => conditions }
  end

  delegate :sort_hash, to: :cur_node

  private

  def find_columns(name)
    form_name, column_name = name.split("/", 2)
    if column_name.blank?
      column_name = form_name
      form_name = nil
    end

    if form_name.present?
      form = Cms::Form.all.site(cur_site).where(name: form_name).first
      return if form.blank?
    end

    criteria = Cms::Column::Base.all.site(cur_site)
    criteria = criteria.where(form_id: form) if form
    criteria = criteria.where(name: column_name)
    criteria.to_a
  end

  def build_column_condition(columns, value)
    return if columns.blank? || value.blank?

    conditions = columns.map do |column|
      column_criteria = column.exact_match_to_value(value)
      next if column_criteria.blank?

      # be sure to set BSON::ObjectId instance for "column_id"
      column_criteria[:column_id] = BSON::ObjectId(column.id.to_s)
      { column_values: { "$elemMatch" => column_criteria } }
    end
    conditions.compact!

    return if conditions.blank?
    return conditions.first if conditions.length == 1

    { "$and" => [{ "$or" => conditions }] }
  end
end
