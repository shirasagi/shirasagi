module Sys::Agents::Addons::Role
  class ViewController < ApplicationController
    include SS::AddonFilter::View
  end
end
