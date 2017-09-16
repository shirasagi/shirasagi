class Webmail::AccountSettingsController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  model SS::User

  menu_view "ss/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("webmail.settings.account"), { action: :show } ]
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

  def edit
    label = t('webmail.default_settings')
    conf = @cur_user.imap_default_settings

    @defaults = {
      host: "#{label} / #{conf[:host]}",
      auth_type: "#{label} / #{conf[:auth_type]}",
      account: "#{label} / #{conf[:account]}",
      password: "#{label} / #{conf[:password].to_s.gsub(/./, '*')}"
    }
  end

  def test_connection
    user = @cur_user.clone
    user.attributes = get_params
    user.valid?

    @imap = Webmail::Imap::Base.new(user)
    @imap.conf[:password] ||= @cur_user.decrypted_password

    if @imap.login
      render plain: "Login Success."
    else
      render plain: @imap.error
    end
  end
end
