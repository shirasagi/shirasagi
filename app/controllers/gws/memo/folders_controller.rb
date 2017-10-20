class Gws::Memo::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Folder

  def set_crumbs
    @crumbs << ['連絡メモ', gws_memo_messages_path ]
    @crumbs << ['管理', gws_memo_folders_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { path: BSON::ObjectId.new.to_s }
  end
end
