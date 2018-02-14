# set member name for sort feature
class SS::Migration20180201000000
  def change
    Gws::Memo::Message.each do |message|
      if message.user && message.from_member_name.blank?
        message.set(from_member_name:  message.user.long_name)
      end
      if message.display_to.present? && message.to_member_name.blank?
        message.set(to_member_name:  message.display_to.join("; "))
      end
    end
  end
end
