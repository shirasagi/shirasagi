namespace :inquiry2 do
  task delete_inquiry2_temp_files: :environment do
    puts "delete_inquiry2_temp_files"
    Inquiry2::DeleteInquiryTempFilesJob.perform_now
  end
end
