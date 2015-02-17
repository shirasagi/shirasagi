class Opendata::Agents::Nodes::CommentController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::UrlHelper

  before_action :accept_cors_request
  before_action :set_idea

  private
    def set_idea
      @idea_path = @cur_path.sub(/\/comment\/.*/, ".html")

      @idea = Opendata::Idea.site(@cur_site).public.
        filename(@idea_path).
        first

      raise "404" unless @idea
    end

  public
    def index
      redirect_to @idea_path
    end

end
