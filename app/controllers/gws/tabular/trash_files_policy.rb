class Gws::Tabular::TrashFilesPolicy < Gws::Tabular::FilesPolicy
  class << self
    def undo_delete?(cur_site, cur_user, model, item)
      new(cur_site: cur_site, cur_user: cur_user, model: model, item: item).undo_delete?
    end
  end

  def undo_delete?
    return false unless item.allowed?(:delete, cur_user, site: cur_site)
    true
  end
end
