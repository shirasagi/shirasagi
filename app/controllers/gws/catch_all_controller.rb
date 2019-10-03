class Gws::CatchAllController < ApplicationController
  include Gws::BaseFilter
  include SS::CatchAllFilter
end
