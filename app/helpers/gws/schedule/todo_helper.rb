module Gws::Schedule::TodoHelper
  def menu_items(action, model=@model, item=@item, site=@cur_site, user=@cur_user)
    result = []

    case action
    when /index/
      result << -> { link_to t('ss.links.new'), action: :new } if model.allowed?(:edit, user, site: site)

    when /new|create|lock|copy/
      result << -> { link_to t('ss.links.back_to_index'), action: :index }

    when /edit|update|delete|move|finish|revert/
      result << -> { link_to t('ss.links.back_to_show'), action: :show, id: item } if item.allowed?(:read, user, site: site)
      result << -> { link_to t('ss.links.back_to_index'), action: :index }

    else
      result << -> { link_to t('ss.links.edit'), action: :edit, id: item } if item.allowed?(:edit, user, site: site)
      result << -> { link_to t('ss.links.copy'), action: :copy, id: item } if item.allowed?(:edit, user, site: site)
      result << -> { link_to t('ss.links.delete'), action: :delete, id: item } if item.allowed?(:delete, user, site: site)

      if item.allowed?(:edit, user, site: site) && !item.finished?
        result << -> { link_to t('gws/schedule/todo.links.finish'), action: :finish, id: item }
      end

      if item.allowed?(:edit, user, site: site) && item.finished?
        result << -> { link_to t('gws/schedule/todo.links.revert'), action: :revert, id: item }
      end

      result << -> { link_to t('ss.links.back_to_index'), action: :index }
    end

    result
  end
end
