FactoryBot.define do
  trait :sys_mail_log do
    mailer { "Inquiry::Mailer" }
  end

  factory :sys_mail_log_utf8, class: Sys::MailLog, traits: [:sys_mail_log] do
    eml = Mail.new(File.read("#{Rails.root}/spec/fixtures/sys/mail_log/UTF-8.eml"))
    subject { eml.subject }
    to { eml.to.join("; ") }
    from { eml.from.join("; ") }
    date { eml.date }
    mail { eml.to_s }
  end

  factory :sys_mail_log_iso, class: Sys::MailLog, traits: [:sys_mail_log] do
    eml = Mail.new(File.read("#{Rails.root}/spec/fixtures/sys/mail_log/ISO-2022-JP.eml"))
    subject { eml.subject }
    to { eml.to.join("; ") }
    from { eml.from.join("; ") }
    date { eml.date }
    mail { eml.to_s }
  end
end
