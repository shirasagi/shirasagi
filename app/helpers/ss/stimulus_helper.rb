module SS::StimulusHelper
  extend ActiveSupport::Concern

  module Utils
    module_function

    def normalize_controller_name(name)
      name = name.to_s.dasherize.gsub("/", "--")
      if name.end_with?("_controller")
        name = name[0..-11]
      end
      name
    end

    def normalize_value_key(name)
      name = name.to_s.dasherize
      if !name.end_with?("-value")
        name += "-value"
      end
      name
    end

    def flatten_params(string_or_array_or_hash)
      ret = []

      case string_or_array_or_hash
      when String, Symbol
        ret += [ :controller, Utils.normalize_controller_name(string_or_array_or_hash) ]
      when Array
        string_or_array_or_hash.each do |controllers|
          ret += Utils.flatten_params(controllers)
        end
      when Hash
        string_or_array_or_hash.each do |key, params|
          key = Utils.normalize_controller_name(key)
          array = [ :controller, key ]
          params.each do |param_name, param_value|
            array << "#{key}-#{Utils.normalize_value_key(param_name)}".to_sym
            array << param_value
          end
          ret += array
        end
      end

      ret
    end

    def convert_to_data_params(string_or_array_or_hash)
      params = {}
      array = Utils.flatten_params(string_or_array_or_hash)
      array.each_slice(2) do |key, value|
        key = key.to_sym unless key.is_a?(Symbol)
        if params.key?(key)
          params[key] = "#{params[key]}, #{value}"
        else
          params[key] = value
        end
      end
      params
    end

    def merge_data_params(options, data)
      options = options.symbolize_keys
      if options.key?(:data)
        options[:data] = options[:data].merge(data)
      else
        options[:data] = data
      end
      options
    end
  end

  def ss_stimulus_tag(controllers, type: :div, **options, &block)
    data = Utils.convert_to_data_params(controllers)
    options = Utils.merge_data_params(options, data)
    tag.send(type, **options, &block)
  end
end
