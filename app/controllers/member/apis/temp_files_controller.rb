class Member::Apis::TempFilesController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include Member::AjaxFileFilter

  model Member::TempFile
end
