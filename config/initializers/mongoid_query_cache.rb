module Mongoid
  module QueryCache
    class << self
      def without_cache
        enabled = QueryCache.enabled?
        QueryCache.enabled = false
        yield
      ensure
        QueryCache.enabled = enabled
      end
    end

    module View
      private
      def cache_key
        #[ collection.namespace, selector, limit, skip, projection ]
        [ collection.namespace, selector, limit, skip, projection, sort ]
      end
    end
  end
end
