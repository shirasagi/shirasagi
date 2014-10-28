class Cms::SearchPagesController < ApplicationController
  include Cms::SearchCollectionFilter

  model Cms::Page
end
