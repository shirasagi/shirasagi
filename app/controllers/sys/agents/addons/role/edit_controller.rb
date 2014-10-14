module Sys::Agents::Addons::Role
  class EditController < ApplicationController
    include SS::AddonFilter::Edit
  end
end
