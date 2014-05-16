# coding: utf-8
module Cms::Permission
  module Resource
    extend ActiveSupport::Concern
    
    module ClassMethods
      public
        def allow(action_with_user)
          #actions = { action: user }
          where({})
        end
    end
    
    public
      def allowed?(action_with_user)
        true
      end
  end
end
