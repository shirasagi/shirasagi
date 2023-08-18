class Gws::CompressJob < Gws::ApplicationJob
  def perform(attr)
    zip = Gws::Compressor.new(user, attr)

    Rails.logger.error("Error : Failed to compress share_files.") unless zip.save

    #Gws::Share::Mailer.compressed_mail(user, zip).deliver_now
    item = Gws::Share::Mailer.compressed_mail(site, zip.user, zip).message

    subject = item.subject
    subject = NKF.nkf("-w", subject) if subject =~ /ISO-2022-JP/i

    message = SS::Notification.new
    message.cur_group     = site
    message.cur_user      = user
    message.member_ids    = [user.id]
    message.send_date     = Time.zone.now
    message.subject       = subject
    message.format        = 'text'
    message.text          = item.decoded
    message.save!
  end
end
