# coding: utf-8
class Cms::Node::MainController < ApplicationController
  include Cms::BaseFilter

  prepend_before_action ->{ redirect_to node_nodes_path }, only: :index

  public
    def index
      # redirect
    end
end
