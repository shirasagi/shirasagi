namespace :web_mail do
  task export_mail_transfer: :environment do
    ::Tasks::WebMail::ExportMailTransfer.exec(ENV["output"])
  end
end
