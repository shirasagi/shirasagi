class Faq::Task::Node::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(opts)
      opts[:task].log "#{opts[:node].url}"

      generate_node_with_pagination opts[:node]
    end
end
