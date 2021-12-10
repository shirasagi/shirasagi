class Cms::Apis::SyntaxCheckController < ApplicationController
  include Cms::BaseFilter

  def check
    contents = params[:contents].to_unsafe_h
    if contents.blank?
      head :bad_request
      return
    end

    result = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)
    render json: { errors: result.errors }
  end
end
