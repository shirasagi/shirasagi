namespace :inquiry_second do
  task delete_inquiry_second_temp_files: :environment do
    puts "delete_inquiry_second_temp_files"
    InquirySecond::DeleteInquiryTempFilesJob.perform_now
  end
end
