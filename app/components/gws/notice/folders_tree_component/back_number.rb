#frozen_string_literal: true

class Gws::Notice::FoldersTreeComponent::BackNumber < ApplicationComponent
  include ActiveModel::Model
  include Gws::Notice::FoldersTreeComponent::Base

  private

  def folders
    @folders ||= begin
      criteria = Gws::Notice::Folder.all
      criteria = criteria.for_post_back_number(cur_site, cur_user)
      criteria = criteria.only(:id, :site_id, :name, :depth, :updated)
      criteria
    end
  end

  def item_url(folder)
    gws_notice_back_numbers_path(folder_id: folder.id)
  end
end
