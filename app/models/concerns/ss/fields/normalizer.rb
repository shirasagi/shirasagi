module SS::Fields::Normalizer
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_fields
    before_save :remove_blank_fields
  end

  private

  def normalize_fields
    self.class.fields.each do |name, field_def|
      next if name[0] == '_'
      m = "normalize_#{field_def.type.to_s.underscore.gsub(/\//, '_')}_field"
      send(m, name, field_def) rescue nil
    end
  end

  def normalize_string_field(name, field_def)
    metadata = field_def.options[:metadata]

    normalize = true
    normalize = metadata.fetch(:normalize, true) if metadata.present?
    return unless normalize

    if field_def.options[:localize]
      hash_value = hash_value_orig = send("#{name}_translations")
      hash_value = hash_value.map { |k, v| [ k, v.present? ? v.strip : v ] }
      hash_value = hash_value.delete_if { |k, v| v.blank? }
      hash_value = Hash[hash_value]
      if hash_value != hash_value_orig
        send("#{name}_translations=", hash_value)
      end
    else
      value = send(name)
      if value.present? && value.length > 1
        value = value.dup
        if value.strip!
          send("#{name}=", value)
        end
      end
    end
  end

  def remove_blank_fields
    self.class.fields.each do |name, field_def|
      next if name[0] == '_'
      next unless field_def.default_val.nil?
      name = "#{name}_translations" if field_def.options[:localize]
      if has_attribute?(name) && blank_attribute?(name, send(name), field_def)
        remove_attribute(name)
      end
    end
  end

  def blank_attribute?(name, val, field_def)
    return true if val.nil?
    return false if boolean_field?(field_def)

    if val.is_a?(String)
      return false if val.length == 1
    end
    val.blank?
  end

  def boolean_field?(field_def)
    field_def.type == Mongoid::Boolean || field_def.type == Boolean
  end
end
