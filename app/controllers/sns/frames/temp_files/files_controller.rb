#frozen_string_literal: true

class Sns::Frames::TempFiles::FilesController < ApplicationController
  include Sns::BaseFilter
  include Sns::CrudFilter
  include SS::TempFilesFrame
end
