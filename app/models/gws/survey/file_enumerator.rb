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
      terms += user_personal_header_terms
    end
    columns.each do |column|
      next if column.is_a?(Gws::Column::Title)
      next if column.is_a?(Gws::Column::Section)

      terms << column.name
    end
    terms
  end

  private

  def columns
    @columns ||= @cur_form.columns.order_by(order: 1, name: 1).to_a
  end

  def enum_record(yielder, item)
    terms = []
    if !@cur_form.anonymous?
      terms += user_personal_record_terms(item)
    end

    columns.each do |column|
      next if column.is_a?(Gws::Column::Title)
      next if column.is_a?(Gws::Column::Section)

      column_value = item.column_values.where(column_id: column.id).first
      if column_value.blank?
        terms << nil
        next
      end

      term = ""
      case column
      when Gws::Column::TextArea
        term << "#{column.prefix_label}\n" if column.prefix_label
        term << column_value.value if column_value.value
        term << "\n#{column.postfix_label}" if column.postfix_label
      when Gws::Column::FileUpload
        if column_value.files.present?
          column_value.files.each do |file|
            term << "\n" if !term.empty?
            term << column.prefix_label if column.prefix_label
            term << file.humanized_name
            term << column.postfix_label if column.postfix_label
          end
        end
      when Gws::Column::RadioButton
        if column_value.try(:other_value?)
          term = "#{column.prefix_label}#{column_value.other_value_text}#{column.postfix_label}"
        else
          term = "#{column.prefix_label}#{column_value.value}#{column.postfix_label}"
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

  def user_personal_header_terms
    terms = []
    terms << Gws::Survey::File.t(:updated)
    terms << Gws::User.t(:name)
    terms << Gws::User.t(:organization_uid)
    terms
  end

  def user_personal_record_terms(item)
    terms = []
    terms << I18n.l(item.updated, format: :csv)
    terms << item.user_name
    terms << (item.user.organization_uid.presence || item.user_uid)
    terms
  end
end
