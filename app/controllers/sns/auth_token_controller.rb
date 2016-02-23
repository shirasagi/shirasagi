class Sns::AuthTokenController < ApplicationController
  def index
    @item = form_authenticity_token
    response.headers['X-CSRF-Token'] = @item
    respond_to do |format|
      format.html do
        response.headers['Content-Type'] = "text/plain"
        render layout: false
      end
      format.json { render }
    end
  end
end
