module SS::CacheableComponent
  extend ActiveSupport::Concern

  class_methods do
    cattr_accessor :expires_in, :cache_key, :perform_caching
    self.expires_in = 1.day
    self.perform_caching = Rails.application.config.action_controller.perform_caching
  end

  def cache_component(&block)
    if cache_configured?
      Rails.cache.fetch(cache_key || {}, expires_in: self.class.expires_in) do
        capture(&block)
      end
    else
      capture(&block)
    end
  end

  def render_erb(erb_html)
    template = ::ERB.new(erb_html)
    template.result(binding)
  end

  def cache_exist?
    if cache_configured?
      Rails.cache.exist?(cache_key || {})
    end
  end

  def delete_cache
    if cache_configured?
      Rails.cache.delete(cache_key || {}) rescue nil
    end
  end

  def cache_configured?
    self.class.perform_caching && Rails.cache
  end

  private

  def cache_key
    key = _effective_cache_key
    if key
      [ :components, virtual_path, key ]
    else
      [ :components, virtual_path ]
    end
  end

  def _effective_cache_key
    return unless self.class.cache_key

    if self.class.cache_key.respond_to?(:call)
      instance_exec(&self.class.cache_key)
    else
      self.class.cache_key.to_s
    end
  end
end
