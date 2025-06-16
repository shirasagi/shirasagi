class InquirySecond::DeleteInquiryTempFilesJob < Cms::ApplicationJob
  def perform
    yesterday = Time.zone.now.yesterday
    ss_files = SS::File.where(model: "inquiry_second/temp_file").where(updated: { "$lt" => yesterday })
    ss_files.destroy_all

    InquirySecond::SavedParams.expired.destroy_all
  end
end
