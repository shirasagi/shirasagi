#frozen_string_literal: true

class Sns::Frames::TempFiles::UploadsController < ApplicationController
  include Sns::BaseFilter
  include SS::TempUploadsFrame
end
