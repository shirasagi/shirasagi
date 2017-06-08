class SS::CsvConverter
  attr_reader :criteria
  attr_reader :field_names

  def initialize(criteria, field_names = nil)
    @criteria = criteria.dup
    @field_names = field_names.presence
    @field_names ||= extract_field_names
  end

  class << self
    def enum_csv(criteria, field_names = nil)
      new(criteria, field_names).enum_csv
    end

    def to_csv(criteria, field_names = nil)
      enum_csv(criteria, field_names).to_a.to_csv
    end
  end

  def extract_field_names
    field_names = @criteria.klass.fields.keys if @criteria.respond_to?(:klass)
    field_names ||= @criteria.fields.keys if @criteria.respond_to?(:fields)

    field_names - %w(_id text_index)
  end

  def enum_csv
    Enumerator.new do |y|
      y << encode_sjis(field_names.to_csv)
      @criteria.each do |item|
        y << encode_sjis(item_to_csv(item).to_csv)
      end
    end
  end

  private
  def item_to_csv(item)
    field_names.map do |h|
      escape_value(h, item[h])
    end
  end

  def escape_value(field_name, value)
    if value.is_a?(DateTime)
      value.strftime("%Y/%m/%d %H:%M")
    else
      value
    end
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end
end
