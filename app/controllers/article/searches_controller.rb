class Article::SearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  prepend_before_action ->{ redirect_to url_for(controller: 'article/pages', action: params[:action]) }
end
