class Sns::CatchAllController < ApplicationController
  include Sns::BaseFilter
  include SS::CatchAllFilter
end
