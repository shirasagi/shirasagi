module Webmail
  class Initializer
    # グループ
    Webmail::Role.permission :edit_webmail_groups
    # ユーザー
    Webmail::Role.permission :edit_webmail_users
    # ロール/権限
    Webmail::Role.permission :edit_webmail_roles
    # 操作履歴
    Webmail::Role.permission :read_webmail_histories

    # グループ代表メールが使えるか？
    Webmail::Role.permission :use_webmail_group_imap_setting

    SS::User.include Webmail::UserExtension
    Cms::User.include Webmail::UserExtension
    Gws::User.include Webmail::UserExtension
  end
end
