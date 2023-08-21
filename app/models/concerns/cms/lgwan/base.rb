module Cms::Lgwan
  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def delegate_lgwan_in_web(name)
        alias_method "#{name}_in_cms", name
        define_method(name) do |*args|
          SS::Lgwan.web? ? send("#{name}_in_web", *args) : send("#{name}_in_cms", *args)
        end
      end
    end
  end
end
