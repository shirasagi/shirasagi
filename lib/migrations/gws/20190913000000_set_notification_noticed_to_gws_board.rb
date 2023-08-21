class SS::Migration20190913000000
  include SS::Migration::Base

  depends_on "20190830000000"

  def change
    criteria = Gws::Board::Topic.all.topic.and_public
    criteria = criteria.where(notify_state: 'enabled')
    criteria = criteria.exists(notification_noticed_at: false)
    criteria.set(notification_noticed_at: Time.zone.now)
  end
end
