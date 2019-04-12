module Webmail::Addon
  module MailBody
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::SanitizeHtml
  end
end
