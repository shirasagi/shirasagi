class Chorg::Frames::Changesets::DivisionsController < ApplicationController
  include Cms::ApiFilter
  include Chorg::Frames::Changesets::MainFilter

  private

  def type
    :division
  end
end
