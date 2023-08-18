module MailPage
  class Initializer
    Cms::Node.plugin "mail_page/page"
    Cms::Part.plugin "mail_page/page"

    SS::File.model "mail_page/page", SS::File
  end
end
