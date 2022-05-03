module Tasks
  module SS
    class << self
      def invoke_task(name, *args)
        task = Rake.application[name]
        task.reenable
        task.invoke(*args)
      end
    end

    module Locale
      module_function

      def generate
        I18n.available_locales.each do |lang|
          json = I18n.t(".", locale: lang).to_json
          json.gsub!(/%{\w+?}/) do |matched|
            "{{#{matched[2..-2]}}}"
          end

          path = "#{Rails.root}/app/javascript/locales/#{lang}.json"
          ::File.open("#{Rails.root}/app/javascript/locales/#{lang}.json", "wt") do |f|
            f.puts "{ \"translation\": #{json} }"
          end
          puts path
        end
      end
    end
  end
end
