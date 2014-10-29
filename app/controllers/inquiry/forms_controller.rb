class Inquiry::FormsController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to inquiry_columns_path }, only: :index

  public
    def index
      # redirect
    end
end
