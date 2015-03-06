class Cms::SearchController < ApplicationController
  include Cms::BaseFilter

  model Cms::Page

  navi_view "cms/main/navi"

  append_view_path "app/views/cms/search"

  public
    def index
    end

    def update
      raise "this"
    end
end
