class Sys::AuthTokenController < ApplicationController
  public
    def index
      @item = form_authenticity_token
      response.headers['X-CSRF-Token'] = @item
      respond_to do |format|
        format.html { render layout: false }
        format.json { render }
      end
    end
end
