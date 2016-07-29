class Cms::Apis::PagesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  def routes
    @items = @model.routes
  end
end
