require 'spec_helper'

describe "gws_portal_portlet", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:todo) { create :gws_schedule_todo, cur_site: site, cur_user: user }

  before do
    login_gws_user
  end

  it do
    visit gws_portal_user_path(site: site, user: user)

    # create to-do portlet.
    click_on I18n.t('gws/portal.links.manage_portlets')
    click_on I18n.t('ss.links.new')
    within '.main-box' do
      click_on I18n.t('gws/portal.portlets.todo.name')
    end
    within 'form#item-form' do
      click_on I18n.t('ss.buttons.save')
    end
    wait_for_notice I18n.t('ss.notice.saved')

    visit gws_portal_user_path(site: site, user: user)
    expect(page).to have_css('.portlets .portlet-model-todo', text: I18n.t('gws/portal.portlets.todo.name'))
    expect(page).to have_css('.portlets .portlet-model-todo .list-item .title', text: todo.name)

    # hide to-do menu and hide to-do portlet.
    site.menu_todo_state = "hide"
    site.update!

    visit gws_portal_user_path(site: site, user: user)
    expect(page).to have_no_css('.portlets .portlet-model-todo', text: I18n.t('gws/portal.portlets.todo.name'))
    expect(page).to have_no_css('.portlets .portlet-model-todo .list-item .title', text: todo.name)

    # show to-do menu and show to-do portlet.
    site.menu_todo_state = "show"
    site.update!

    visit gws_portal_user_path(site: site, user: user)
    expect(page).to have_css('.portlets .portlet-model-todo', text: I18n.t('gws/portal.portlets.todo.name'))
    expect(page).to have_css('.portlets .portlet-model-todo .list-item .title', text: todo.name)
  end
end
