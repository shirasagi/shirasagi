class Faq::SearchesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  prepend_before_action ->{ redirect_to url_for(controller: 'faq/pages', action: params[:action]) }
end
