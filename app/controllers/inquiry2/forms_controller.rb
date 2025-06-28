class Inquiry2::FormsController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to inquiry2_columns_path }, only: :index

  def index
    # redirect
  end
end
