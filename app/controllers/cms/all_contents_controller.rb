class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter

  def index
    respond_to do |format|
      format.html
      format.csv { send_data Cms::AllContent.csv.encode("SJIS"), filename: "all_contents.csv" }
    end
  end
end
