class Webmail::MFALoginController < ApplicationController
  include Webmail::BaseFilter
  include Sns::MFALoginFilter
end
