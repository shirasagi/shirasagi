# coding: utf-8
module SS::Permission
  module User
    extend ActiveSupport::Concern
    
    public
      def allowed?(action_with_resource)
        true
      end
  end
end
