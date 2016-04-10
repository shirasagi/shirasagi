class Sns::Login::EnvironmentController < ApplicationController
  include Sns::BaseFilter
  include Sns::LoginFilter

  skip_action_callback :verify_authenticity_token, only: :consume
  skip_action_callback :logged_in?
  before_action :set_item

  model Sys::Auth::Environment

  private
    def set_item
      @item ||= @model.find_by(filename: params[:id])
      raise "404" if @item.blank?
    end

  public
    def login
      key = @item.keys.find do |key|
        request.env[key].present?
      end
      if key.blank?
        render_login nil, nil
        return
      end

      uid_or_email = request.env[key]
      user = SS::User.uid_or_email(uid_or_email).and_enabled.first
      if user.blank?
        render_login nil, nil
        return
      end

      render_login user, nil, session: true
    end
end
