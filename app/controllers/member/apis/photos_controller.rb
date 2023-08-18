class Member::Apis::PhotosController < ApplicationController
  include Cms::ApiFilter

  model Member::Photo
end
