class Cms::SyntaxChecker::UnfavorableWordsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::UnfavorableWord
  navi_view "cms/syntax_checker/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.syntax_check"), cms_syntax_checker_main_path]
    @crumbs << [t("mongoid.models.cms/unfavorable_word"), url_for(action: :index)]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
