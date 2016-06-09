module Sys::SiteCopy::Cache
  extend ActiveSupport::Concern

  def cache_store
    @cache_store ||= {}
  end

  def cache(id, *keys, &block)
    cache_store[id] ||= {}
    cache = cache_store[id]
    return cache if keys.blank?
    return cache[keys] if cache.key?(keys)

    cache[keys] = ret = yield if block_given?
    ret
  end

  def cache?(id, *keys)
    cache = cache_store[id]
    return false if cache.blank?

    cache.key?(keys)
  end
end
