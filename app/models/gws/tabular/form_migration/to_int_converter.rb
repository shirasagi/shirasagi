class Gws::Tabular::FormMigration::ToIntConverter < Gws::Tabular::FormMigration::BaseConverter
  def call(value)
    case value
    when Hash
      if value.key?(I18n.default_locale) || value.key?(I18n.default_locale.to_s)
        call(value[I18n.default_locale].presence || value[I18n.default_locale.to_s])
      else
        call(value.values.first)
      end
    when Array
      call(value.first)
    else
      if value.try(:numeric?)
        value.to_i
      else
        Rails.logger.info { "unable to convert \"#{value}\" to integer" }
        errors.add :base, "unable to convert \"#{value}\" to integer"
        effective_default_value
      end
    end
  rescue => e
    Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    errors.add :base, "unable to convert \"#{value}\" to integer"
    nil
  end

  private

  def effective_default_value
    return if default_value.nil?

    case default_value
    when BSON::Decimal128
      value = default_value.to_big_decimal
    when SS::Extensions::Decimal128
      value = default_value.value
    else
      value = default_value
    end

    value.to_i
  end
end
