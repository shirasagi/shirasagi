module SS::Config
  class << self
    def config_paths
      @config_paths ||= [ "#{Rails.root}/config/defaults".freeze, "#{Rails.root}/config".freeze ].freeze
    end

    def setup
      @@config = {}
      config_paths.each do |config_path|
        Dir.glob("#{config_path}/*.yml").each do |path|
          @@config[File.basename(path, '.yml').to_sym] = nil
        end
      end
      self
    end

    def env
      return send(:environment) if @@config[:environment]
      @@config[:environment] = true
      load_config(:environment, nil)
    end

    def load_config(name, section = nil)
      conf = {}
      config_paths.each do |config_path|
        path = "#{config_path}/#{name}.yml"
        conf = conf.deep_merge(load_yml(path, section)) if ::File.exist?(path)
      end

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
      # super
    end

    def respond_to?(name, *args)
      @@config.key?(name.to_sym)
    end

    def respond_to_missing?(*args)
      true
    end
  end
end
