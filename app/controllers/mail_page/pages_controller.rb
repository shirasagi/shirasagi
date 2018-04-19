class MailPage::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model MailPage::Page

  append_view_path "app/views/cms/pages"

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end
end
