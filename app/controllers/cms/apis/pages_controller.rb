class Cms::Apis::PagesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Page
end
