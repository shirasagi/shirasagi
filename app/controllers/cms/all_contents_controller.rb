class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  def index
    respond_to do |format|
      format.html
      format.csv do
        send_data Cms::AllContent.csv(@cur_site).encode("SJIS", invalid: :replace, undef: :replace), filename: "all_contents.csv"
      end
    end
  end
end
