module History::Cms::Diff
  module_function

  def init(model, field, value1, value2)
    if field == "column_values"
      return History::Cms::Diff::ColumnValues.new(model, field, value1, value2)
    end

    klass = "History::Cms::Diff::#{value1.class}".constantize rescue nil
    klass ||= History::Cms::Diff::Base
    klass.send(:new, model, field, value1, value2)
  end
end
