module Cms::NodeHelper
  extend ActiveSupport::Concern

  def contents_path(node)
    route = node.view_route.presence || node.route
    "/.s#{node.site.id}/" + route.pluralize.sub("/", "-#{node.id}/")
  rescue StandardError => e
    raise(e) unless Rails.env.production?
    node_nodes_path(cid: node)
  end

  def node_navi(mod_name = nil, &block)
    h = []

    if block
      h << %(<nav class="mod-navi">).html_safe
      h << %(<h2>#{t("modules.#{mod_name}")}</h2>).html_safe if mod_name
      h << capture(&block)
      h << %(</nav>).html_safe

      h << %(<nav class="mod-navi">).html_safe
      h << mod_navi { %(<h2 class="icon-material icon-material-display">#{t('cms.switch_module')}</h2>).html_safe }
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
      if page_approval_request_expired?(item)
        css_class = "state-#{item.status}-remind"
        content += t("workflow.state_remind_suffix")
      elsif page_publication_expired?(item)
        css_class = "state-#{item.status}-expired"
        content += t("cms.state_expired_suffix")
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

  def cms_preview_links(item)
    path = cms_preview_path(path: item.preview_path)
    h = []
    h << link_to(t("ss.links.pc_preview"), path, target: "_blank", rel: "noopener")
    h << link_to(t("ss.links.sp_preview"), path, class: 'cms-preview-sp', target: "_blank", rel: "noopener")

    if @cur_site.mobile_enabled?
      path = cms_preview_path(path: item.mobile_preview_path)
      h << link_to(t("ss.links.mobile_preview"), path, class: 'cms-preview-mb', target: "_blank", rel: "noopener")
    end

    h.map { |c| c.html_safe }
  end

  def link_to_layout(item)
    url = item.parent ? node_layout_path(cid: item.parent, id: item) : cms_layout_path(id: item)
    link_to(item.name, url)
  end

  def link_to_part(item)
    url = item.parent ? node_part_path(cid: item.parent, id: item) : cms_part_path(id: item)
    link_to(item.name, url)
  end

  private

  def page_approval_request_expired?(item)
    return false if item.status != "request"
    return false if !item.is_a?(Cms::Model::Page)
    return false if !@cur_site.try(:approve_remind_state_enabled?)

    duration = SS::Duration.parse(@cur_site.approve_remind_later)
    Workflow.exceed_remind_limit?(duration, item)
  end

  def page_publication_expired?(item)
    return false if item.status != "public"
    return false if !item.is_a?(Cms::Model::Page)
    return false if !@cur_site.try(:page_expiration_enabled?)

    item.updated < @cur_site.page_expiration_at
  end
end
