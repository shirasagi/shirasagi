class Opendata::Agents::Nodes::MyIdeaController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::MypageFilter

  public
    def index
      render nothing: true
    end
end
