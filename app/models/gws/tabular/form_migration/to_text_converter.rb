class Gws::Tabular::FormMigration::ToTextConverter < Gws::Tabular::FormMigration::BaseConverter
  def call(value)
    case value
    when Hash
      if value.key?(I18n.default_locale) || value.key?(I18n.default_locale.to_s)
        call(value[I18n.default_locale].presence || value[I18n.default_locale.to_s])
      else
        call(value.values.first)
      end
    when Array
      value.map { call(_1) }.join(",")
    else
      value.to_s.presence || effective_default_value
    end
  rescue => e
    Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    errors.add :base, "unable to convert \"#{value}\" to text"
    nil
  end

  private

  def effective_default_value
    return if default_value.blank?

    case default_value
    when Hash
      default_value[I18n.default_locale].to_s
    else
      default_value.to_s
    end
  end
end
