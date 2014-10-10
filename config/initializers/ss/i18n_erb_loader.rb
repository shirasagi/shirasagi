module I18n
  module Backend
    module Base

      protected
        def load_erb(filename)
          begin
            require 'erb'
            erb = ERB.new IO.read(filename)
            YAML::load erb.result
          rescue TypeError, ScriptError, StandardError => e
            raise InvalidLocaleData.new(filename, e.inspect)
          end
        end
        #alias_method :load_yml, :load_erb
    end
  end
end
