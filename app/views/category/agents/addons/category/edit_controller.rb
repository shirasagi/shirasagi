module Category::Addons::Category
  class EditController < ApplicationController
    include SS::AddonFilter::EditCell
  end
end
