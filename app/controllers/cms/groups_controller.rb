class Cms::GroupsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SearchableCrudFilter

  model Cms::Group

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.group", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

    def set_item
      super
      raise "403" unless Cms::Group.site(@cur_site).include?(@item)
    end
end
