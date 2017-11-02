module Sys::Webmail
  class AccountsController < ApplicationController
    include Sys::BaseFilter
    include Sys::CrudFilter

    model Webmail::User

    private
      def set_crumbs
        @crumbs << [t("sys.webmail_account"), import_sys_webmail_accounts_path]
      end

      def fix_params
        { cur_user: @cur_user }
      end

    public
      def index
        raise "404"
      end

      def import
        raise "403" unless @model.allowed?(:edit, @cur_user)

        @item = @model.new
        return if request.get?

        @item.attributes = get_params
        result = @item.import_csv
        flash.now[:notice] = t("ss.notice.saved") if result
        render_create result, location: { action: :import }, render: { file: :import }
      end

      def download
        raise "403" unless @model.allowed?(:read, @cur_user)

        items = @model.all.allow(:read, @cur_user)
        @item = @model.new
        send_data @item.export_csv(items), filename: "webmail_accounts_#{Time.zone.now.to_i}.csv"
      end
  end
end
