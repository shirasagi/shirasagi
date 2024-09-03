require 'spec_helper'

# 承認経路はユーザー1のみが閲覧・管理可能で、申請フォームはユーザー1とユーザー2との共同管理の時、
# ユーザー2が申請フォームを編集すると、申請フォームにセットした承認経路が外れる問題の修正
describe "gws_workflow2_form_applications", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:role) do
    permissions = %w(
      use_gws_workflow2
      read_private_gws_workflow2_forms edit_private_gws_workflow2_forms delete_private_gws_workflow2_forms
      read_private_gws_workflow2_routes edit_private_gws_workflow2_routes delete_private_gws_workflow2_routes
    )
    create(:gws_role, cur_site: site, permissions: permissions)
  end
  let!(:user1) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ role.id ]) }
  let!(:user2) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: [ role.id ]) }
  # let!(:category1) { create :gws_workflow2_form_category, cur_site: site, order: 10 }
  # let!(:purpose1) { create :gws_workflow2_form_purpose, cur_site: site, order: 10 }
  let!(:route) do
    create(
      :gws_workflow2_route, cur_site: site, cur_user: user1,
      readable_setting_range: "private", readable_group_ids: [], readable_member_ids: [ user1.id ], readable_custom_group_ids: [],
      group_ids: [], user_ids: [ user1.id ], custom_group_ids: [])
  end
  let(:name) { "name-#{unique_id}" }
  let(:memo) { Array.new(2) { "memo-#{unique_id}" } }

  it do
    login_user user1
    visit gws_workflow2_form_forms_path(site: site)
    within ".nav-menu" do
      click_on I18n.t("ss.links.new")
    end
    within "form#item-form" do
      fill_in "item[name]", with: name
      select route.name, from: "item[default_route_id]"

      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    expect(Gws::Workflow2::Form::Base.all.count).to eq 1
    form = Gws::Workflow2::Form::Base.all.first
    expect(form).to be_a(Gws::Workflow2::Form::Application)
    expect(form.name).to eq name
    expect(form.default_route_id).to eq route.id.to_s

    login_user user2
    visit gws_workflow2_form_forms_path(site: site)
    click_on form.name
    within ".nav-menu" do
      click_on I18n.t("ss.links.edit")
    end
    within "form#item-form" do
      fill_in "item[memo]", with: memo.join("\n")

      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    form.reload
    expect(form.name).to eq name
    expect(form.memo).to eq memo.join("\r\n")
    expect(form.default_route_id).to eq route.id.to_s
  end
end
