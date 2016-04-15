module Mongoid
  module QueryCache
    module View
      private
      def cache_key
        #[ collection.namespace, selector, limit, skip, projection ]
        [ collection.namespace, selector, limit, skip, projection, sort ]
      end
    end
  end
end
