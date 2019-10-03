class Cms::CatchAllController < ApplicationController
  include Cms::BaseFilter
  include SS::CatchAllFilter
end
