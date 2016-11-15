class Cms::WordDictionariesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::WordDictionary
  navi_view "cms/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"cms.word_dictionary", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end
end
