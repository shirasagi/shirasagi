namespace :webmail do
  task export_mail_transfer: :environment do
    require_relative "./export_mail_transfer"
    ::Tasks::Webmail::ExportMailTransfer.exec(ENV["output"])
  end
end
