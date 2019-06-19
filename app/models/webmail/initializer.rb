module Webmail
  class Initializer
    # アカウント
    Webmail::Role.permission :read_webmail_accounts
    Webmail::Role.permission :edit_webmail_accounts
    # グループ
    Webmail::Role.permission :edit_webmail_groups
    # ユーザー
    Webmail::Role.permission :edit_webmail_users
    # ロール/権限
    Webmail::Role.permission :edit_webmail_roles
    # 操作履歴
    Webmail::Role.permission :read_webmail_histories

    # グループ代表メールが使えるか？
    Webmail::Role.permission :use_webmail_group_imap_setting, module_name: 'webmail/group_imap'

    # グループ代表メールのフォルダーの管理
    Webmail::Role.permission :edit_webmail_group_imap_mailboxes, module_name: 'webmail/group_imap'

    # グループ代表メールの署名の管理
    Webmail::Role.permission :edit_webmail_group_imap_signatures, module_name: 'webmail/group_imap'

    # グループ代表メールのフィルターの管理
    Webmail::Role.permission :edit_webmail_group_imap_filters, module_name: 'webmail/group_imap'

    # グループ代表メールのキャッシュの管理
    Webmail::Role.permission :edit_webmail_group_imap_caches, module_name: 'webmail/group_imap'

    SS::File.model "webmail/history/archive_file", Webmail::History::ArchiveFile

    SS::User.include Webmail::UserExtension
    Cms::User.include Webmail::UserExtension
    Gws::User.include Webmail::UserExtension
  end
end
