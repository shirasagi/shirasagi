module Webmail::BaseFilter
  extend ActiveSupport::Concern
  include Sns::BaseFilter

  included do
    helper Webmail::MailHelper
    navi_view "webmail/main/navi"
    before_action :set_webmail_mode
  end

  private
    def set_webmail_mode
      @ss_mode = :webmail
    end

    def set_crumbs
      #@crumbs << [:'modules.webmail', webmail_mails_path]
    end
end
