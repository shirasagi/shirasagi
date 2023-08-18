module SS
  module LocaleSupport
    module_function

    def sample_lang
      languages = I18n.available_locales
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
      @current_lang ||= begin
        lang = SS::LocaleSupport.sample_lang
        puts "run specs with lang=#{lang}"
        lang
      end
    end

    module Hooks
      def self.extended(obj)
        obj.around do |example|
          Rails.logger.tagged(SS::LocaleSupport.current_lang.to_s) do
            example.run
          end
        end

        # rubocop:disable Rails/I18nLocaleAssignment
        obj.after do
          I18n.locale = I18n.default_locale if I18n.locale != I18n.default_locale
        end
        # rubocop:enable Rails/I18nLocaleAssignment
      end
    end
  end
end

RSpec.configuration.extend(SS::LocaleSupport::Hooks)
