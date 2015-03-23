module SS::Config
  def SS.config
    SS::Config
  end

  class << self
    def method_missing(name, *args, &block)
      file  = "#{Rails.root}/config/#{name}.yml"
      conf  = File.exists?(file) ? YAML.load_file(file)[Rails.env] : {}
      klass = "#{name.to_s.camelize}::Config".constantize rescue nil
      conf  = klass.default_values.merge(conf) if klass
      # raise NoMethodError, "undefined method `#{name}'" if conf.blank?
      conf_struct = OpenStruct.new(conf).freeze

      define_singleton_method(name) { conf_struct }
      conf_struct
    end

    def env
      file  = "#{Rails.root}/config/environment.yml"
      conf  = YAML.load_file(file)
      conf  = SS::Config::Environment.default_values.merge(conf)
      conf_struct = OpenStruct.new(conf).freeze

      define_singleton_method(:env) { conf_struct }
      conf_struct
    end
  end

  module Environment
    cattr_reader(:default_values) do
      {
        storage: "file",
        max_filesize: 104_857_600
      }
    end
  end
end
