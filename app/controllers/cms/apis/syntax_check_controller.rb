class Cms::Apis::SyntaxCheckController < ApplicationController
  include Cms::BaseFilter

  def check
    safe_params = params.require(:item).permit(contents: [ :id, :content, :resolve, :type, content: [] ])
    contents = safe_params[:contents]
    if contents.blank?
      render json: { errors: [] }
      return
    end

    result = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)
    render json: { errors: result.errors }
  end

  def correct
    content = params[:content].to_unsafe_h
    collector = params[:collector].to_s
    collector_params = params[:params].try(:to_unsafe_h)
    result = Cms::SyntaxChecker.correct(
      cur_site: @cur_site, cur_user: @cur_user, content: content, collector: collector, params: collector_params
    )
    render json: { result: result.result }
  end
end
