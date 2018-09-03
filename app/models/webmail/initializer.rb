module Webmail
  class Initializer
    # ロール/権限
    Webmail::Role.permission :edit_webmail_roles

    # グループ代表メールが使えるか？
    Webmail::Role.permission :use_webmail_group_imap_setting
    # グループ代表メールを管理できるか？
    Webmail::Role.permission :edit_webmail_group_imap_setting

    # ユーザーのメールボックス容量を閲覧できるか？
    Webmail::Role.permission :read_webmail_individual_usage

    SS::User.include Webmail::UserExtension
    SS::User.include Webmail::Reference::Role

    Cms::User.include Webmail::UserExtension
    Gws::User.include Webmail::UserExtension
  end
end
