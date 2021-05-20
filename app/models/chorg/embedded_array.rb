class Chorg::EmbeddedArray
  attr_reader :field_name
  attr_reader :update_array

  def initialize(field_name, update_array)
    @field_name = field_name
    @update_array = update_array
  end

  def update_entity(entity)
    return if !entity.respond_to?(field_name)
    return if entity.column_values.size != update_array.size

    entity.send(field_name).each_with_index do |embedded_entity, i|
      hash = update_array[i]
      hash.select { |k, v| v.present? }.each { |k, v| embedded_entity[k] = v }
    end
  end
end
