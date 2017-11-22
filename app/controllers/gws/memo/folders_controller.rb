class Gws::Memo::FoldersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Memo::Folder

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_memo_label || t('mongoid.models.gws/memo/message'), gws_memo_messages_path ]
    @crumbs << [t('mongoid.models.gws/memo/folder'), gws_memo_folders_path ]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

end
