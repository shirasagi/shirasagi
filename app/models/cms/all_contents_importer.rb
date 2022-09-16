class Cms::AllContentsImporter
  include Cms::PageImportBase

  self.required_headers = ->{ [ I18n.t("all_content.page_id"), I18n.t("all_content.node_id"), model.t(:filename) ] }

  private

  def define_importers(importer)
    super
    define_importer_list(importer)
    define_importer_st_category(importer)
  end

  def define_importer_list(importer)
    scope = "mongoid.attributes.cms/addon/list/model"
    importer.simple_column :conditions, name: I18n.t("conditions", scope: scope)
    importer.simple_column :sort, name: I18n.t("sort", scope: scope) do |row, item, head, value|
      if item.respond_to?(:sort=)
        sort = from_label(value, item.sort_options)
        item.sort = sort.presence
      end
    end
    importer.simple_column :limit, name: I18n.t("limit", scope: scope)
    importer.simple_column :new_days, name: I18n.t("new_days", scope: scope)
    importer.simple_column :loop_format, name: I18n.t("loop_format", scope: scope) do |row, item, head, value|
      if item.respond_to?(:loop_format=)
        loop_format = from_label(value, item.loop_format_options)
        item.loop_format = loop_format.presence
      end
    end
    importer.simple_column :upper_html, name: I18n.t("upper_html", scope: scope)
    importer.simple_column :loop_setting_id, name: I18n.t("loop_setting_id", scope: scope) do |row, item, head, value|
      if item.respond_to?(:loop_setting=)
        item.loop_setting = value.present? ? Cms::LoopSetting.site(site).where(name: value).first : nil
      end
    end
    importer.simple_column :loop_html, name: I18n.t("loop_html", scope: scope)
    importer.simple_column :lower_html, name: I18n.t("lower_html", scope: scope)
    importer.simple_column :loop_liquid, name: I18n.t("loop_liquid", scope: scope)
    importer.simple_column :no_items_display_state, name: I18n.t("no_items_display_state", scope: scope) do |_r, item, _h, value|
      if item.respond_to?(:no_items_display_state=)
        no_items_display_state = from_label(value, item.no_items_display_state_options)
        item.no_items_display_state = no_items_display_state.presence
      end
    end
    importer.simple_column :substitute_html, name: I18n.t("substitute_html", scope: scope)
  end

  def define_importer_st_category(importer)
    importer.simple_column :st_categories, name: I18n.t("category.setting") do |row, item, head, value|
      if item.respond_to?(:st_category_ids=)
        category_ids = category_name_tree_to_ids(to_array(value))
        categories = Category::Node::Base.site(site).in(id: category_ids)
        item.st_category_ids = categories.pluck(:id)
      end
    end
  end

  def find_or_initialize!(row)
    page_id = value(row, I18n.t("all_content.page_id"))
    if page_id
      return Cms::Page.site(site).find(page_id)
    end

    node_id = value(row, I18n.t("all_content.node_id"))
    if node_id
      return Cms::Node.site(site).find(node_id)
    end

    raise I18n.t('errors.messages.both_of_page_id_and_node_id_is_blank')
  end

  def allowed_to_import?(item)
    if item.new_record?
      node = item.parent
      is_owned = node ? node.owned?(user) : item.root_owned?(user)
    else
      is_owned = item.owned?(user)
    end

    permits = []
    if I18n.exists?("import_private_#{item.class.permission_name}")
      permits << "import_private_#{item.class.permission_name}"
      permits << "import_public_#{item.class.permission_name}" if is_owned
    else
      permits << "edit_private_#{item.class.permission_name}"
      permits << "edit_public_#{item.class.permission_name}" if is_owned
    end

    user.cms_role_permit_any?(site, permits)
  end
end
