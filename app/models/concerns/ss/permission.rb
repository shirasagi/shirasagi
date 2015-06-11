module SS::Permission
  extend ActiveSupport::Concern

  included do
    class_variable_set(:@@_permission_name, nil)
    class_variable_set(:@@_permission_action, nil)
  end

  public
    def allowed?(action, user, opts = {})
      false
    end

    def permission_action
      self.class.class_variable_get(:@@_permission_action)
    end

  module ClassMethods
    public
      def allowed?(action, user, opts = {})
        self.new.allowed?(action, user, opts)
      end

      def allow(action, user, opts = {})
        false
      end

      def permission_name
        class_variable_get(:@@_permission_name) || self.to_s.tableize.gsub(/\//, "_")
      end

      def permission_action
        class_variable_get(:@@_permission_action)
      end

    private
      def set_permission_name(name, fix_action = nil)
         class_variable_set(:@@_permission_name, name)
         class_variable_set(:@@_permission_action, fix_action)
      end
  end
end
