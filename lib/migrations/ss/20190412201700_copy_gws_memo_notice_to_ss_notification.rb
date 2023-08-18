class SS::Migration20190412201700
  include SS::Migration::Base

  depends_on "20190320000000"

  def change
    Mongoid.default_client["gws_memo_notices"].find.each do |item|
      notice = SS::Notification.new
      notice.member_ids = item['member_ids']
      notice.text = item['text']
      notice.html = item['html']
      notice.seen = item['seen']
      notice.deleted = item['deleted']
      notice.state = item['state']
      notice.created = item['created'].try(:in_time_zone)
      notice.updated = item['updated'].try(:in_time_zone)
      notice.subject = item['subject']
      notice.format = item['format']
      notice.send_date = item['send_date'].try(:in_time_zone)
      notice.user_id = item['user_id']
      notice.group_id = item['site_id']
      notice.url = item['url']
      notice.save
    end
  end
end
