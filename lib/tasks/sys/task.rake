namespace :sys do
  namespace :mail_log do
    task sweep: :environment do
      puts "delete mail_log"
      Sys::MailLogSweepJob.perform_now
    end
  end
end
