class Gws::Tabular::File::ValuesDrop < Liquid::Drop
  def initialize(item)
    super()
    @item = item
  end

  def [](name)
    field_name = find_field_name(name)
    if field_name
      value = @item.read_tabular_value(field_name)
      if @item.class.to_liquid_factory_map.key?(field_name)
        value = @item.class.to_liquid_factory_map[field_name].call(value)
      end
      return value
    end

    super
  end

  def key?(name)
    found = find_field_name(name)
    return true if found

    super
  end

  private

  def logical_field_name_map
    return @logical_field_name_map if instance_variable_defined?(:@logical_field_name_map)

    @logical_field_name_map = {}
    @item.class.field_name_map.each do |field_name, translations|
      translations.each do |lang, logical_field_name|
        @logical_field_name_map[logical_field_name] ||= field_name
        @logical_field_name_map["#{logical_field_name}.#{lang}"] ||= field_name
      end
    end

    @logical_field_name_map
  end

  def find_field_name(logical_field_name)
    logical_field_name_map["#{logical_field_name}.#{I18n.locale}"] || logical_field_name_map[logical_field_name]
  end
end
