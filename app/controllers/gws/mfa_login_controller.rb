class Gws::MFALoginController < ApplicationController
  include HttpAcceptLanguage::AutoLocale
  include Gws::BaseFilter
  include Sns::MFALoginFilter
end
