module Webmail
  class Initializer
    SS::User.include Webmail::UserExtension
  end
end
