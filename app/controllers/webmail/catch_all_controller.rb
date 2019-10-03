class Webmail::CatchAllController < ApplicationController
  include Webmail::BaseFilter
  include SS::CatchAllFilter
end
