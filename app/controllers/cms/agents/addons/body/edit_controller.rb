module Cms::Agents::Addons::Body
  class EditController < ApplicationController
    include SS::AddonFilter::Edit

    javascript "cms/form"
  end
end
