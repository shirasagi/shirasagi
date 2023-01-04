class Chorg::Frames::Changesets::UnifiesController < ApplicationController
  include Cms::ApiFilter
  include Chorg::Frames::Changesets::MainFilter

  private

  def type
    :unify
  end
end
