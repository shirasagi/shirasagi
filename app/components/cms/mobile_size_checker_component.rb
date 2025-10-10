class Cms::MobileSizeCheckerComponent < ApplicationComponent
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :checker
end
