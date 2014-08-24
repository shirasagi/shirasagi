# coding: utf-8
module Workflow
  class Initializer
    Cms::Page.addon "workflow/approver"
    
    Cms::Role.permission :release_other_article_pages
    Cms::Role.permission :release_private_article_pages
    Cms::Role.permission :release_other_cms_pages
    Cms::Role.permission :release_private_cms_pages
    Cms::Role.permission :release_other_faq_pages
    Cms::Role.permission :release_private_faq_pages
    Cms::Role.permission :approve_other_article_pages
    Cms::Role.permission :approve_private_article_pages
    Cms::Role.permission :approve_other_cms_pages
    Cms::Role.permission :approve_private_cms_pages
    Cms::Role.permission :approve_other_faq_pages
    Cms::Role.permission :approve_private_faq_pages    

  end
end
