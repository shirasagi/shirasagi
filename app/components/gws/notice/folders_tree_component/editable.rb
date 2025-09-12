#frozen_string_literal: true

class Gws::Notice::FoldersTreeComponent::Editable < ApplicationComponent
  include ActiveModel::Model
  include Gws::Notice::FoldersTreeComponent::Base

  private

  def folders
    @folders ||= begin
      criteria = Gws::Notice::Folder.all
      criteria = criteria.for_post_editor(cur_site, cur_user)
      criteria = criteria.only(:id, :site_id, :name, :depth, :updated)
      criteria
    end
  end

  def item_url(folder)
    gws_notice_editables_path(folder_id: folder.id)
  end
end
