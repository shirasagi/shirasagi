require 'spec_helper'

describe "gws_workflow2_routes", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  # システム管理者が作った承認ルート
  let!(:route0) { create(:gws_workflow2_route, cur_site: site) }

  before do
    login_gws_user
  end

  it do
    visit gws_workflow2_routes_path(site: site)
    within ".list-items" do
      click_on route0.name
    end
    within ".nav-menu" do
      click_on I18n.t('ss.links.copy')
    end
    wait_for_js_ready
    within "form#item-form" do
      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    route = Gws::Workflow2::Route.find_by(name: "[#{I18n.t("workflow.cloned_name_prefix")}] #{route0.name}")
    expect(route.site_id).to eq site.id
    expect(route.approvers).to eq route0.approvers
    expect(route.circulations).to eq route0.circulations
    expect(route.group_ids).to be_blank
    expect(route.user_ids).to eq [ gws_user.id ]
  end
end
