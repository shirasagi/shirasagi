class SS::MoreContentComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :max_height
end
