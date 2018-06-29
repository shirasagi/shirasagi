class Webmail::AccountSettingsController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  model SS::User

  menu_view "ss/crud/resource_menu"

  skip_before_action :imap_initialize
  before_action :set_default_settings

  private

  def set_crumbs
    @crumbs << [t("webmail.settings.account"), { action: :show } ]
  end

  def fix_params
    { self_edit: true }
  end

  def permit_fields
    [
      :imap_host, :imap_auth_type, :imap_account, :in_imap_password,
      :imap_sent_box, :imap_draft_box, :imap_trash_box,
      {
        imap_settings: [
          :name, :from, :address, :imap_host, :imap_auth_type, :imap_account, :in_imap_password,
          :imap_sent_box, :imap_draft_box, :imap_trash_box, :threshold_mb,
          :default
        ]
      },
    ]
  end

  def set_item
    @item = @cur_user
  end

  def set_default_settings
    label = t('webmail.default_settings')
    conf = @cur_user.imap_default_settings

    @defaults = {
      from: @cur_user.name,
      address: conf[:address],
      host: "#{label} / #{conf[:host]}",
      auth_type: "#{label} / #{conf[:auth_type]}",
      account: "#{label} / #{conf[:account]}",
      password: "#{label} / #{conf[:password].to_s.gsub(/./, '*')}"
    }
  end

  public

  def show
    # render
  end

  def edit
    #
  end

  def test_connection
    setting = Webmail::ImapSetting.new
    setting.merge!(get_params.to_h.symbolize_keys)
    setting.set_imap_password
    setting.valid?

    @imap = Webmail::Imap::Base.new(@cur_user, setting)
    @imap.conf[:password] ||= @cur_user.decrypted_password

    if @imap.login
      render plain: "Login Success."
    else
      render plain: @imap.error
    end
  end
end
