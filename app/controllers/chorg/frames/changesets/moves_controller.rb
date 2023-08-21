class Chorg::Frames::Changesets::MovesController < ApplicationController
  include Cms::ApiFilter
  include Chorg::Frames::Changesets::MainFilter

  private

  def type
    :move
  end
end
