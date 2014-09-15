# coding: utf-8
class Article::Task::Node::PagesController < ApplicationController
  include Cms::ReleaseFilter::Page

  public
    def generate(task, node)
      task.log "#{node.url}"

      generate_node node
    end
end
