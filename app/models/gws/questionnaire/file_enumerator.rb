class Gws::Questionnaire::FileEnumerator < Enumerator
  def initialize(items, params)
    @items = items
    @cur_site = params[:cur_site]
    @cur_form = params[:cur_form]
    @encoding = params[:encoding]
    @params = params

    super() do |y|
      y << bom + encode(headers.to_csv)
      @items.each do |item|
        enum_record(y, item)
      end
    end
  end

  def headers
    terms = []
    @cur_form.columns.each do |column|
      terms << column.name
    end
    if !@cur_form.anonymous?
      terms << Gws::User.t(:name)
      terms << Gws::Questionnaire::File.t(:updated)
    end
    terms
  end

  private

  def enum_record(yielder, item)
    terms = []
    @cur_form.columns.order_by(order: 1, name: 1).each do |column|
      column_value = item.column_values.where(column_id: column.id).first
      terms << "#{column.try(:prefix_label)}#{column_value ? column_value.value : ''}#{column.try(:postfix_label)}"
    end

    if !@cur_form.anonymous?
      terms << item.user_long_name
      terms << I18n.l(item.updated)
    end

    yielder << encode(terms.to_csv)
  end

  def bom
    return '' if @encoding == 'Shift_JIS'
    "\uFEFF"
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @params.encoding == 'Shift_JIS'
    str
  end
end
