class Inquiry2::DeleteInquiryTempFilesJob < Cms::ApplicationJob
  def perform
    yesterday = Time.zone.now.yesterday
    ss_files = SS::File.where(model: "inquiry2/temp_file").where(updated: { "$lt" => yesterday })
    ss_files.destroy_all

    Inquiry2::SavedParams.expired.destroy_all
  end
end
