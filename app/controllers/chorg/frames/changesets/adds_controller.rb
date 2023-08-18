class Chorg::Frames::Changesets::AddsController < ApplicationController
  include Cms::ApiFilter
  include Chorg::Frames::Changesets::MainFilter

  private

  def type
    :add
  end
end
