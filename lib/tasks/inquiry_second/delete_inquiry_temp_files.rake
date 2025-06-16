namespace :inquiry do
  task delete_inquiry_temp_files: :environment do
    puts "delete_inquiry_temp_files"
    Inquiry::DeleteInquiryTempFilesJob.perform_now
  end
end
