module SS::AgentFilter
  extend ActiveSupport::Concern

  included do
    before_action :inherit_variables
  end

  private

  def controller
    @controller
  end

  def inherit_variables
    controller.instance_variables.select { |m| m =~ /^@[a-z]/ }.each do |name|
      next if instance_variable_defined?(name)
      instance_variable_set name, controller.instance_variable_get(name)
    end
  end

  public

  def stylesheets
    controller.stylesheets
  end

  def stylesheet(path, **options)
    controller.stylesheet(path, **options)
  end

  def javascripts
    controller.javascripts
  end

  def javascript(path, **options)
    controller.javascript(path, **options)
  end

  def opengraph(key, *values)
    controller.opengraph(key, *values)
  end

  def twitter_card(key, *values)
    controller.twitter_card(key, *values)
  end

  def filters
    @filters ||= begin
      request.env["ss.filters"] ||= []
    end
  end

  def filter_include?(key)
    filters.any? { |f| f == key || f.is_a?(Hash) && f.key?(key) }
  end

  def filter_include_any?(*keys)
    keys.any? { |key| filter_include?(key) }
  end

  def filter_options(key)
    found = filters.find { |f| f == key || f.is_a?(Hash) && f.key?(key) }
    return if found.nil?
    return found[key] if found.is_a?(Hash)
    true
  end

  def mobile_path?
    filter_include?(:mobile)
  end

  def preview_path?
    filter_include?(:preview)
  end

  def javascript_configs
    controller.javascript_configs
  end

  def javascript_config(conf)
    controller.javascript_config(conf)
  end
end
