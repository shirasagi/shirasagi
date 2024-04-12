class Sns::MFALoginController < ApplicationController
  include HttpAcceptLanguage::AutoLocale
  include Sns::BaseFilter
  include Sns::MFALoginFilter
end
