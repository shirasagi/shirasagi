class Event::Task::Node::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(opts)
      generate_node opts[:node]
    end
end
