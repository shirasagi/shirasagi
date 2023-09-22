class SS::Migration20181009202100
  include SS::Migration::Base

  depends_on "20180402000000"

  def change
    all_ids = Webmail::Signature.all.exists(host: false).pluck(:id)
    all_ids.each_slice(20) do |ids|
      Webmail::Signature.all.in(id: ids).to_a.each do |signature|
        scope = default_account_scope(signature)
        next if scope.blank?

        signature.host = scope[:host]
        signature.account = scope[:account]

        signature.without_record_timestamps { signature.save }
      end
    end
  end

  def default_account_scope(signature)
    user = signature.user
    return [] if user.blank?

    if user.imap_settings.blank?
      setting = Webmail::ImapSetting.default
    else
      setting = user.imap_settings[0]
    end

    imap = Webmail::Imap::Base.new_by_user(user, setting)
    imap.account_scope
  end
end
