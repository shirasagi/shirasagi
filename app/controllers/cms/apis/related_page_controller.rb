class Cms::Apis::RelatedPageController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page

  def routes
    @items = @model.routes
  end
end
