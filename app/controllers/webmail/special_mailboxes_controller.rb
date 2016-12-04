class Webmail::SpecialMailboxesController < ApplicationController
  include Webmail::BaseFilter
  include Sns::CrudFilter

  model SS::User

  menu_view "ss/crud/resource_menu"

  private
    def set_crumbs
      @crumbs << [:"webmail.settings.special_mailbox", { action: :show } ]
    end

    def fix_params
      { self_edit: true }
    end

    def permit_fields
      [:imap_sent_box, :imap_draft_box, :imap_trash_box]
    end

    def set_item
      @item = @cur_user
    end

  public
    def show
      # render
    end
end
