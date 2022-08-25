module SS
  module LocaleSupport
    module_function

    def sample_lang(example)
      type = example.metadata[:type]
      return I18n.default_locale if type.blank?

      type = type.to_sym
      return I18n.default_locale unless %i[feature].include?(type)

      languages = Array(example.metadata[:locale].presence).map(&:to_sym)
      if languages.blank?
        languages = I18n.available_locales
      end

      if ENV["RSPEC_LOCALE"].present?
        languages &= ENV["RSPEC_LOCALE"].split(",").map(&:to_sym)
      end

      if languages.present?
        languages.sample
      else
        I18n.default_locale
      end
    end

    def current_lang
      @current_lang
    end

    def current_lang=(lang)
      @current_lang = lang
    end

    module Hooks
      def self.extended(obj)
        obj.around(:all) do |example|
          lang = SS::LocaleSupport.current_lang = SS::LocaleSupport.sample_lang(example)
          Rails.logger.tagged(lang.to_s) do
            example.run
          end
        ensure
          SS::LocaleSupport.current_lang = nil
        end
        # rubocop:disable Rails/I18nLocaleAssignment
        obj.after(:each) do
          I18n.locale = I18n.default_locale if I18n.locale != I18n.default_locale
        end
        # rubocop:enable Rails/I18nLocaleAssignment
      end
    end
  end
end

RSpec.configuration.extend(SS::LocaleSupport::Hooks)
