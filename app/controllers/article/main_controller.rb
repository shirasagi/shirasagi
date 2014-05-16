# coding: utf-8
class Article::MainController < ApplicationController
  include Cms::BaseFilter
  
  prepend_before_action ->{ redirect_to article_pages_path }, only: :index
  
  public
    def index
      # redirect
    end
end
