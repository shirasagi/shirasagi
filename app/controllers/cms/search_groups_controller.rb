class Cms::SearchGroupsController < ApplicationController
  include Cms::SearchCollectionFilter

  model Cms::Group
end
