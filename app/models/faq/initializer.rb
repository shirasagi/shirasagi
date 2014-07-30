# coding: utf-8
module Faq
  class Initializer
    Cms::Node.plugin "faq/page"

    Faq::Page.addon "faq/body"
    Faq::Node::Page.addon "category/setting"

    Cms::Role.permission :read_other_faq_pages
    Cms::Role.permission :read_private_faq_pages
    Cms::Role.permission :edit_other_faq_pages
    Cms::Role.permission :edit_private_faq_pages
    Cms::Role.permission :delete_other_faq_pages
    Cms::Role.permission :delete_private_faq_pages
  end

  #Cms::Page.instance_exec do
  #  def addon(*args)
  #    Faq::Page.addon(*args) and super
  #  end
  #end
  Faq::Page.inherit_addons Cms::Page, except: "cms/body"
end
