class Sns::AccessTokenController < ApplicationController
  include SS::BaseFilter

  def create
    @cur_user.access_token = SecureRandom.hex(12)
    @cur_user.access_token_expiration_date = 10.minutes.from_now
    @cur_user.save

    render plain: @cur_user.access_token
  end
end
