class Sns::AccessTokenController < ApplicationController
  include SS::BaseFilter

  def create
    safe_params = params.permit(:login_path, :logout_path)

    token = SS::AccessToken.new(cur_user: @cur_user)
    token.attributes = safe_params
    token.create_token
    raise '403' unless token.save

    render plain: token.token
  end
end
