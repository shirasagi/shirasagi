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
      normalize = true
      normalize = field_def.metadata.fetch(:normalize, true) if field_def.metadata
      return unless normalize
      value = send(name)
      if value.present? && value.length > 1
        value = value.dup
        if value.strip!
          send("#{name}=", value)
        end
      end
    end

    def remove_blank_fields
      self.class.fields.each do |name, field_def|
        next if name[0] == '_'
        next unless field_def.default_val.nil?
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
        val.blank?
      else
        val.blank?
      end
    end

    def boolean_field?(field_def)
      field_def.type == Mongoid::Boolean || field_def.type == Boolean
    end
end
