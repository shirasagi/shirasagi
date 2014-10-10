class Urgency::MainController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to urgency_layouts_path }, only: :index

  public
    def index
      # redirect
    end
end
