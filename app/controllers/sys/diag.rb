module Sys::Diag
  if Rails.env.development?
    class HttpsController < ApplicationController
      include Sys::BaseFilter

      navi_view "sys/diag/main/navi"
      menu_view nil

      private

      def set_crumbs
        @crumbs << ["HTTTP Test", action: :index]
      end

      public

      def index
        raise "403" unless SS::User.allowed?(:edit, @cur_user)
        raise "403" unless Rails.env.development?
      end
    end
  end
end
