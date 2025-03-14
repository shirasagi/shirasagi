#frozen_string_literal: true

class Cms::TempFileCreator < SS::TempFileCreator
  attr_accessor :cur_node

  def model
    Cms::TempFile
  end

  def new_item
    model.new(cur_site: cur_site, cur_user: cur_user, cur_node: cur_node)
  end
end
