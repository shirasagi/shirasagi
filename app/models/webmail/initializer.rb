module Webmail
  class Initializer
    # ユーザー
    Webmail::Role.permission :edit_webmail_users
    # ロール/権限
    Webmail::Role.permission :edit_webmail_roles
    # 操作履歴
    Webmail::Role.permission :read_webmail_histories

    # グループ代表メールが使えるか？
    Webmail::Role.permission :use_webmail_group_imap_setting
    # グループ代表メールを管理できるか？
    Webmail::Role.permission :edit_webmail_group_imap_setting

    # ユーザーのメールボックス容量を閲覧できるか？
    Webmail::Role.permission :read_webmail_individual_usage

    SS::User.include Webmail::UserExtension
    Cms::User.include Webmail::UserExtension
    Gws::User.include Webmail::UserExtension
  end
end
