#frozen_string_literal: true

class Cms::Frames::TempFiles::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::TempFilesFrame
end
