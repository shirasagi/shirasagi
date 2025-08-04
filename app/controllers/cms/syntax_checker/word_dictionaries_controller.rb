class Cms::SyntaxChecker::WordDictionariesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::WordDictionary
  navi_view "cms/syntax_checker/main/conf_navi"

  private

  def set_crumbs
    @crumbs << [t("cms.syntax_check"), cms_syntax_checker_main_path]
    @crumbs << [t("cms.word_dictionary"), url_for(action: :index)]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
