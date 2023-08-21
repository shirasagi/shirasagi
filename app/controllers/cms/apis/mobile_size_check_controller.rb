class Cms::Apis::MobileSizeCheckController < ApplicationController
  include Cms::BaseFilter

  def check
    checker = Cms::MobileSizeChecker.new(cur_site: @cur_site, cur_user: @cur_user)
    checker.html = params[:html].to_s

    checker.validate
    render json: { errors: checker.errors.full_messages }
  end
end
