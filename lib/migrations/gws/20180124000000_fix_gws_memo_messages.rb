# set to_member_ids
class SS::Migration20180124000000
  include SS::Migration::Base

  depends_on "20170523000000"

  def change
    Gws::Memo::Message.each do |message|
      if message.member_ids.present? && message.to_member_ids.blank?
        message.to_member_ids = message.member_ids
        message.without_record_timestamps { message.save }
      end
    end
  end
end
