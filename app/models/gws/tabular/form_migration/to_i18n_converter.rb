class Gws::Tabular::FormMigration::ToI18nConverter < Gws::Tabular::FormMigration::BaseConverter
  def call(value)
    case value
    when Hash
      value
    when Array
      value = value.map(&:to_s).join(",")
      if value.present?
        { I18n.default_locale => value }
      else
        effective_default_value
      end
    else
      value = value.to_s
      if value.present?
        { I18n.default_locale => value.to_s }
      else
        effective_default_value
      end
    end
  rescue => e
    Rails.logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    errors.add :base, "unable to convert \"#{value}\" to i18n text"
    nil
  end

  private

  def effective_default_value
    return if default_value.blank?

    case default_value
    when Hash
      default_value
    else
      { I18n.default_locale => default_value.to_s }
    end
  end
end
