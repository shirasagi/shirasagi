class Gws::Share::CompressJob < Gws::ApplicationJob
  def perform(attr)
    zip = Gws::Share::Compressor.new(user, attr)

    Rails.logger.error("Error : Failed to compress share_files.") unless zip.save

    Gws::Share::Mailer.compressed_mail(user, zip).deliver_now
  end
end
