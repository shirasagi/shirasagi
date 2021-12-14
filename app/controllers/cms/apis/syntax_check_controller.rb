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

  def correct
    content = params[:content].to_unsafe_h
    collector = params[:collector].to_s
    if content.blank? || collector.blank?
      head :bad_request
      return
    end

    collector_params = params[:params].try(:to_unsafe_h)
    result = Cms::SyntaxChecker.correct(
      cur_site: @cur_site, cur_user: @cur_user, content: content, collector: collector, params: collector_params
    )
    render json: { result: result.result }
  end
end
