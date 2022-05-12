class Article::SearchesController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to article_pages_path }, only: :index

  def index
    # redirect
  end
end
