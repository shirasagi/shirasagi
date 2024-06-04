module SS
  module FeatureSupport
    class RackAppBase
      def initialize(app, decorator)
        @app = app
        @decorator = decorator
      end

      attr_accessor :app, :decorator

      def call(env)
        decorator.call(env) if decorator
        app.call(env)
      end
    end

    module Hooks
      def self.extended(obj)
        obj.after(:example) do
          ::SS::FeatureSupport.remove_all_request_decorators
        end
      end
    end

    mattr_accessor :decorated_controllers, default: []

    module_function

    def add_request_decorator(controller_class, decorator_proc)
      controller_class.middleware_stack.use ::SS::FeatureSupport::RackAppBase, decorator_proc
      ::SS::FeatureSupport.decorated_controllers << controller_class
    end

    def remove_all_request_decorators
      ::SS::FeatureSupport.decorated_controllers.each do |controller_class|
        controller_class.middleware_stack.delete ::SS::FeatureSupport::RackAppBase
      end
      ::SS::FeatureSupport.decorated_controllers.clear
    end
  end
end

RSpec.configuration.extend(SS::FeatureSupport::Hooks)
RSpec.configuration.include(SS::FeatureSupport)
