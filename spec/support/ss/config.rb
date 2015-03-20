# extends SS::Config methods for testability.
module SS::Config
  class << self
    def replace_at(name, hash)
      config = build_config(hash)
      define_singleton_method(name) { config }
    end

    def replace_value_at(name, key, value)
      config = SS.config.send(name).to_h
      config[key] = value
      replace_at(name, config)
    end

    private
      def build_config(hash)
        hash.is_a?(OpenStruct) ? hash.freeze : OpenStruct.new(hash).freeze
      end
  end
end
