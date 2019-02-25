class SS::Migration20190221000000
  def change
    all_ids = Gws::Memo::Notice.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Gws::Memo::Notice.in(id: ids).to_a.each do |item|
        notice = SS::Notification.new
        notice.file_ids = item.file_ids
        notice.member_ids = item.member_ids
        notice.text = item.text
        notice.html = item.html
        notice.seen = item.seen
        notice.deleted = item.deleted
        notice.state = item.state
        notice.created = item.created
        notice.updated = item.updated
        notice.export = item.export
        notice.subject = item.subject
        notice.format = item.format
        notice.send_date = item.send_date
        notice.user_id = item.user_id
        notice.site_id = item.site_id
        notice.url = item.url
        notice.save
      end
    end
  end
end
