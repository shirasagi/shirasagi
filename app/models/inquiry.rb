#frozen_string_literal: true

module Inquiry
  MenuItem = Data.define(:label, :path_proc, :css_classes) do
    def initialize(label:, path_proc:, css_classes: nil)
      super
    end

    def path(*args, **kwargs)
      path_proc.call(*args, **kwargs)
    end
  end

  module_function

  def enum_menu_items(cur_site, cur_node, cur_user)
    Enumerator.new do |y|
      # Personal Plans
      menu_item_inquiry_columns(cur_site, cur_node, cur_user).try { y << _1 }
      menu_item_inquiry_answers(cur_site, cur_node, cur_user).try { y << _1 }
      menu_item_inquiry_results(cur_site, cur_node, cur_user).try { y << _1 }
      menu_item_inquiry_feedbacks(cur_site, cur_node, cur_user).try { y << _1 }
    end
  end

  def menu_item_inquiry_columns(cur_site, cur_node, cur_user)
    return unless cur_node.route == "inquiry/form"
    return unless cur_node.allowed?(:read, cur_user, site: cur_site)
    return unless Inquiry::Column.allowed?(:read, cur_user, site: cur_site, node: cur_node)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.inquiry_columns_path(*args, site: cur_site, cid: cur_node, **kwargs) }
    MenuItem.new(label: I18n.t("inquiry.column"), path_proc: path_proc)
  end

  def menu_item_inquiry_answers(cur_site, cur_node, cur_user)
    return unless cur_node.route == "inquiry/form"
    return unless cur_node.allowed?(:read, cur_user, site: cur_site)
    return unless Inquiry::Answer.allowed?(:read, cur_user, site: cur_site, node: cur_node)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.inquiry_answers_path(*args, site: cur_site, cid: cur_node, **kwargs) }
    MenuItem.new(label: I18n.t("inquiry.answer"), path_proc: path_proc)
  end

  def menu_item_inquiry_results(cur_site, cur_node, cur_user)
    return unless cur_node.route == "inquiry/form"
    return unless cur_node.allowed?(:read, cur_user, site: cur_site)
    return unless Inquiry::Answer.allowed?(:read, cur_user, site: cur_site, node: cur_node)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.inquiry_results_path(*args, site: cur_site, cid: cur_node, **kwargs) }
    MenuItem.new(label: I18n.t("inquiry.result"), path_proc: path_proc)
  end

  def menu_item_inquiry_feedbacks(cur_site, cur_node, cur_user)
    return unless cur_node.route == "inquiry/form"
    return unless cur_node.allowed?(:edit, cur_user, site: cur_site)
    return unless Inquiry::Answer.allowed?(:read, cur_user, site: cur_site, node: cur_node)

    helpers = Rails.application.routes.url_helpers
    path_proc = ->(*args, **kwargs) { helpers.inquiry_feedbacks_path(*args, site: cur_site, cid: cur_node, **kwargs) }
    MenuItem.new(label: I18n.t("inquiry.feedback"), path_proc: path_proc)
  end
end
