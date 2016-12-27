module SS::Config
  class << self
    def setup
      @@config = {}
      Dir.glob("#{Rails.root}/config/defaults/*.yml").each do |path|
        @@config[File.basename(path, '.yml').to_sym] = nil
      end
      self
    end

    def env
      return send(:environment) if @@config[:environment]
      @@config[:environment] = true
      load_config(:environment, nil)
    end

    def load_config(name, section = nil)
      conf = load_yml("#{Rails.root}/config/defaults/#{name}.yml", section)
      path = "#{Rails.root}/config/#{name}.yml"
      conf = conf.deep_merge(load_yml(path, section)) if File.exists?(path)

      struct = OpenStruct.new(conf).freeze
      define_singleton_method(name) { struct }
      struct
    end

    def load_yml(file, section = nil)
      conf = YAML.load_file(file)
      section ? conf[section] : conf
    end

    def method_missing(name, *args, &block)
      load_config(name, Rails.env) if @@config.key?(name)
      #super
    end

    def respond_to?(name, *args)
      @@config.key?(name)
    end

    def respond_to_missing?(*args)
      true
    end
  end
end
