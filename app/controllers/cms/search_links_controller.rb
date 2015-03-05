class Cms::SearchLinksController < ApplicationController
  include Cms::SearchFilter

  public
    def index
      @items = @items.sort_by(&:filename)

      @pages = []
      @layouts = []
      @parts = []
    end
end
