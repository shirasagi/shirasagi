class Contact::SearchGroupsController < ApplicationController
  include Cms::SearchCollectionFilter

  model Cms::Group
end
