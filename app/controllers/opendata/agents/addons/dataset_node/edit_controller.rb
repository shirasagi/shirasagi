module Opendata::Agents::Addons::DatasetNode
  class EditController < ApplicationController
    include SS::AddonFilter::Edit
    helper Cms::FormHelper
  end
end
