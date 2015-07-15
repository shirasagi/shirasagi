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
      return if name.include?("html") || name.include("text")
      return unless field_def.metadata.fetch(:normalize, true)
      value = send(name)
      if value.present? && value.length > 1
        if value.strip!
          send("#{name}=", value)
        end
      end
    end

    def remove_blank_fields
      self.class.fields.each do |name, field_def|
        next if name[0] == '_'
        next if field_def.default_val
        remove_attribute(name) if has_attribute?(name) && send(name).blank?
      end
    end
end
