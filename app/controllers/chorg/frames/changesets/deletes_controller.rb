class Chorg::Frames::Changesets::DeletesController < ApplicationController
  include Cms::ApiFilter
  include Chorg::Frames::Changesets::MainFilter

  private

  def type
    :delete
  end
end
