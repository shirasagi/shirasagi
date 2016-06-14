module SS::Config
  class << self
    def config_exists?(name)
      main_conf = "#{Rails.root}/config/defaults/#{name}.yml"
      user_conf = "#{Rails.root}/config/#{name}.yml"
      File.exists?(main_conf) || File.exists?(user_conf)
    end

    def load_config(name, section = nil)
      main_conf = load_yml("#{Rails.root}/config/defaults/#{name}.yml", section)
      user_conf = load_yml("#{Rails.root}/config/#{name}.yml", section)
      main_conf = main_conf.deep_merge(user_conf) if user_conf

      conf_struct = OpenStruct.new(main_conf).freeze
      define_singleton_method(name) { conf_struct }

      conf_struct
    end

    def load_yml(file, section = nil)
      return {} unless File.exists?(file)
      conf = YAML.load_file(file)
      section ? conf[section] : conf
    end

    def env
      load_config(:environment)
    end

    def method_missing(name, *args, &block)
      load_config(name, Rails.env)
    end

    def respond_to?(name, *args)
      config_exists?(name)
    end

    def respond_to_missing?(*args)
      true
    end
  end
end
