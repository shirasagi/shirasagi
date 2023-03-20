module Cms::Lgwan
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def delegate_lgwan_inweb(name)
        alias_method "#{name}_in_lgcms", name
        define_method(name) do |*args|
          SS::Lgwan.inweb? ? send("#{name}_in_inweb", *args) : send("#{name}_in_lgcms", *args)
        end
      end
    end
  end
end
