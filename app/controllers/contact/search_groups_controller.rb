class Contact::SearchGroupsController < ApplicationController
  include Cms::SearchFilter

  model Cms::Group
end
