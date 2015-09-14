class Ezine::BacknumbersController < ApplicationController
  include Cms::BaseFilter

  private
    def fix_params
      { cur_site: @cur_site, cur_node: @cur_node }
    end

  public
    def index
      # TODO:
      render nothing: true
    end
end
