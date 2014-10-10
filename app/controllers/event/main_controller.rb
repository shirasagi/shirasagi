class Event::MainController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to event_pages_path }, only: :index

  public
    def index
      # redirect
    end
end
