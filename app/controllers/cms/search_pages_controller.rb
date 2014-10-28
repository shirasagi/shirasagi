class Cms::SearchPagesController < ApplicationController
  include Cms::SearchFilter

  model Cms::Page
end
