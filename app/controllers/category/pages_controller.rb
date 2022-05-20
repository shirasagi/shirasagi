class Category::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  prepend_before_action ->{ redirect_to url_for(controller: 'category/nodes', action: params[:action]) }
end
