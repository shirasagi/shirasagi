class Category::PagesController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to category_nodes_path }, only: :index

  def index
    # redirect
  end
end
