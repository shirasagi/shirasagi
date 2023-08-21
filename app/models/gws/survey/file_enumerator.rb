class Gws::Survey::FileEnumerator < Enumerator
  def initialize(items, params)
    @items = items.criteria.dup
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
    if !@cur_form.anonymous?
      terms << Gws::Survey::File.t(:updated)
      terms << Gws::User.t(:name)
      terms << Gws::User.t(:organization_uid)
    end
    @cur_form.columns.each do |column|
      terms << column.name
    end
    terms
  end

  private

  def enum_record(yielder, item)
    terms = []
    if !@cur_form.anonymous?
      terms << I18n.l(item.updated)
      terms << item.user_name
      terms << (item.user.organization_uid.presence || item.user_uid)
    end

    @cur_form.columns.order_by(order: 1, name: 1).each do |column|
      column_value = item.column_values.where(column_id: column.id).first
      if column_value.blank?
        terms << nil
        next
      end

      term = ""
      if column.is_a?(Gws::Column::TextArea)
        term << "#{column.prefix_label}\n" if column.prefix_label
        term << column_value.value if column_value.value
        term << "\n#{column.postfix_label}" if column.postfix_label
      elsif column.is_a?(Gws::Column::FileUpload)
        if column_value.files.present?
          column_value.files.each do |file|
            term << "\n" if !term.empty?
            term << column.prefix_label if column.prefix_label
            term << file.humanized_name
            term << column.postfix_label if column.postfix_label
          end
        end
      else
        term = "#{column.prefix_label}#{column_value.value}#{column.postfix_label}"
      end

      terms << term
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
