class Webmail::AccountSettingsController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  model SS::User

  menu_view "ss/crud/resource_menu"

  private
    def set_crumbs
      @crumbs << [:"webmail.settings.account", { action: :show } ]
    end

    def fix_params
      { self_edit: true }
    end

    def permit_fields
      [ :imap_host, :imap_auth_type, :imap_account, :in_imap_password,
        :imap_sent_box, :imap_draft_box, :imap_trash_box ]
    end

    def set_item
      @item = @cur_user
    end

  public
    def show
      # render
    end

    def test_connection
      user = @cur_user.clone
      user.attributes = get_params
      user.valid?

      @imap = Webmail::Imap.set_user(user)

      if @imap.login
        render text: "Login Success."
      else
        render text: @imap.error
      end
    end
end
