module Cms::Agents::Addons::Role
  class ViewController < ApplicationController
    include SS::AddonFilter::View
  end
end
