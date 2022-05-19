module Cms::NodeHelper
  def contents_path(node)
    route = node.view_route.presence || node.route
    "/.s#{node.site.id}/" + route.pluralize.sub("/", "#{node.id}/")
  rescue StandardError => e
    raise(e) unless Rails.env.production?
    node_nodes_path(cid: node)
  end

  def node_navi(mod_name = nil, &block)
    h = []

    if block
      h << %(<nav class="mod-navi">).html_safe

      if mod_name
        mod_name = t("modules.#{mod_name}")
        h << mod_navi { %(<h2>#{mod_name}</h2>).html_safe }
      end

      h << capture(&block)
      h << %(</nav>).html_safe
    end

    h << render(partial: "cms/node/main/node_navi")
    #h << render(partial: "cms/main/navi")
    safe_join(h)
  end

  def mod_navi(&block)
    mods = Cms::Node.modules.map do |name, key|
      if key == "cms"
        %(<li>#{link_to name, node_nodes_path(mod: "cms")}</li>).html_safe
      else
        %(<li>#{link_to name, send("#{key}_main_path")}</li>).html_safe
      end
    end

    h = []
    h << %(<div class="dropdown dropdown-toggle">).html_safe
    h << capture(&block) if block
    h << %(<ul class="dropdown-menu">#{safe_join(mods)}</ul>).html_safe
    h << %(</div>).html_safe

    safe_join(h)
  end

  def colored_state_label(item)
    return "" unless item.respond_to?(:status)

    if %w(public ready request remand).include?(item.status)
      css_class = "state-#{item.status}"
      content = t("ss.state.#{item.status}")
      if item.status == "request" && @cur_site.try(:approve_remind_state_enabled?)
        duration = SS::Duration.parse(@cur_site.approve_remind_later)
        if Workflow.exceed_remind_limit?(duration, item)
          css_class = "state-#{item.status}-remind"
          content += t("workflow.state_remind_suffix")
        end
      elsif item.status == "public" && @cur_site.try(:page_expiration_enabled?)
        if item.updated < @cur_site.page_expiration_at
          css_class = "state-#{item.status}-expired"
          content += t("cms.state_expired_suffix")
        end
      end
    elsif item.first_released.blank?
      css_class = "state-edit"
      content = t("ss.state.edit")
    else
      css_class = "state-closed"
      content = t("ss.state.closed")
    end

    tag.span(content, class: [ "state", css_class ])
  end

  def cms_syntax_check_enabled?(options = nil)
    if options && options.fetch(:column, false) && @cur_column
      check = @cur_column.syntax_check_enabled?
      return check unless check
    end

    if @cur_node && @cur_node.respond_to?(:syntax_check_enabled?)
      check = @cur_node.syntax_check_enabled?
      return check unless check
    end

    if @cur_site
      check = @cur_site.syntax_check_enabled?
      return check unless check
    end

    if options && options.fetch(:parent, false) && @item && @item.parent && @item.parent.respond_to?(:syntax_check_enabled?)
      check = @item.parent.syntax_check_enabled?
      return check unless check
    end

    check
  end
end
