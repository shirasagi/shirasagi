class Article::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Workflow::PageFilter

  model Article::Page

  append_view_path "app/views/cms/pages"
  navi_view "article/main/navi"
  lang_view "cms/node/pages/lang"

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

  #public
    # Cms::PageFilter
end
