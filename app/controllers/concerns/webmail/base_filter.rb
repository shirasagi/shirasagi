module Webmail::BaseFilter
  extend ActiveSupport::Concern
  include Sns::BaseFilter

  included do
    helper Webmail::MailHelper
    navi_view "webmail/main/navi"
  end

  private
    def set_crumbs
      #@crumbs << [:'modules.webmail', webmail_mails_path]
    end
end
