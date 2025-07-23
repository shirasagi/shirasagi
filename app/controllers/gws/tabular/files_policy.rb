class Gws::Tabular::FilesPolicy
  include ActiveModel::Model

  attr_accessor :cur_site, :cur_user, :model, :item

  class << self
    def index?(cur_site, cur_user, model)
      new(cur_site: cur_site, cur_user: cur_user, model: model).index?
    end

    def create?(cur_site, cur_user, model)
      new(cur_site: cur_site, cur_user: cur_user, model: model).create?
    end
    alias new? create?
    alias copy? create?

    def download_all?(cur_site, cur_user, model)
      new(cur_site: cur_site, cur_user: cur_user, model: model).download_all?
    end

    def import?(cur_site, cur_user, model)
      new(cur_site: cur_site, cur_user: cur_user, model: model).import?
    end

    def show?(cur_site, cur_user, model, item)
      new(cur_site: cur_site, cur_user: cur_user, model: model, item: item).show?
    end

    def update?(cur_site, cur_user, model, item)
      new(cur_site: cur_site, cur_user: cur_user, model: model, item: item).update?
    end
    alias edit? update?

    def destroy?(cur_site, cur_user, model, item)
      new(cur_site: cur_site, cur_user: cur_user, model: model, item: item).destroy?
    end
    alias delete? destroy?
  end

  def index?
    model.allowed?(:read, cur_user, site: cur_site)
  end

  def create?
    model.allowed?(:edit, cur_user, site: cur_site)
  end
  alias new? create?
  alias copy? create?

  def download_all?
    model.allowed?(:download, cur_user, site: cur_site)
  end

  def import?
    model.allowed?(:import, cur_user, site: cur_site)
  end

  def show?
    item.allowed?(:read, cur_user, site: cur_site)
  end

  def update?
    # 非公開でない場合、編集/更新はできない
    return false if item.respond_to?(:closed?) && !item.closed?

    # 承認者の編集が許可されている場合、編集可能
    workflow_requested = item.respond_to?(:workflow_requested?) && item.workflow_requested?
    if workflow_requested
      workflow_request = item.find_workflow_request_to(cur_user)
      if workflow_request.present? && workflow_request[:editable]
        return true
      end
    end

    # 編集者の場合、承認を申請していなければ編集可能
    if item.allowed?(:edit, cur_user, site: cur_site)
      return !workflow_requested
    end

    false
  end
  alias edit? update?

  def destroy?
    return false unless item.allowed?(:delete, cur_user, site: cur_site)
    if item.respond_to?(:closed?) && !item.closed?
      return false
    end
    return false if item.respond_to?(:workflow_requested?) && item.workflow_requested?

    true
  end
  alias delete? destroy?
end
