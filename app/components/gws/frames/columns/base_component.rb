class Gws::Frames::Columns::BaseComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :item

  renders_one :extra_header
end
