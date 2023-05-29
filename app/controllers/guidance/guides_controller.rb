class Guidance::GuidesController < ApplicationController
  include Cms::BaseFilter

  def index
    redirect_to guidance_results_path
  end
end
