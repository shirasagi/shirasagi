class Cms::Apis::SyntaxCheckController < ApplicationController
  include Cms::BaseFilter

  def check
    safe_params = params.require(:item).permit(contents: [ :id, :content, :resolve, :type, content: [] ])
    contents = safe_params[:contents]
    if contents.blank?
      render json: { errors: [] }
      return
    end

    contents = contents.map { Cms::SyntaxChecker::Content.from_hash(_1) }
    result = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)
    errors_json = result.errors.map { _1.to_compat_hash }
    render json: { errors: errors_json }
  end

  def correct
    content = Cms::SyntaxChecker::Content.from_hash(params[:content].to_unsafe_h)
    corrector = params[:collector].to_s
    corrector_params = params[:params].try(:to_unsafe_h)
    result = Cms::SyntaxChecker.correct(
      cur_site: @cur_site, cur_user: @cur_user, content: content, corrector: corrector, params: corrector_params
    )
    render json: { result: result.result }
  end
end
