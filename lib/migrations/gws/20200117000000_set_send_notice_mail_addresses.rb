class SS::Migration20200117000000
  include SS::Migration::Base

  depends_on "20191029000001"

  def change
    each_user do |user|
      if user[:send_notice_mail_address].blank? || user.send_notice_mail_addresses.present?
        user.unset(:send_notice_mail_address)
        next
      end

      send_notice_mail_addresses = [ user[:send_notice_mail_address].presence ].compact
      next if send_notice_mail_addresses.blank?

      user.set(send_notice_mail_addresses: send_notice_mail_addresses)
      user.unset(:send_notice_mail_address)
    end
  end

  private

  def each_user(&block)
    criteria = Gws::User.all.active.exists(send_notice_mail_address: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
