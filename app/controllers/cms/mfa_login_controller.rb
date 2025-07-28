class Cms::MFALoginController < ApplicationController
  include Cms::BaseFilter
  include Sns::MFALoginFilter
end
