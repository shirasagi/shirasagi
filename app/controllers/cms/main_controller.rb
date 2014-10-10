class Cms::MainController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to cms_contents_path }, only: :index

  navi_view "cms/main/navi"

  public
    def index
      # redirect
    end
end
