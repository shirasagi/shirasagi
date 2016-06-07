class Member::Apis::TempFilesController < ApplicationController
  include SS::BaseFilter
  include SS::CrudFilter
  include Member::AjaxFileFilter

  model Member::TempFile

  private
    def fix_params
      { cur_member: @cur_member }
    end
end
