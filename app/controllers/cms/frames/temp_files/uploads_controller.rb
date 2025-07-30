#frozen_string_literal: true

class Cms::Frames::TempFiles::UploadsController < ApplicationController
  include Cms::BaseFilter
  include SS::TempUploadsFrame
end
