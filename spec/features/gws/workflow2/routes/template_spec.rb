require 'spec_helper'

# 管理者が作成した承認ルートをテンプレートとしてカスタマイズし、個人ルートとして保存できること。
describe "gws_workflow2_routes", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  # システム管理者が作った承認ルート
  let!(:route0) do
    create(
      :gws_workflow2_route, cur_site: site, cur_user: gws_user, readable_setting_range: "public",
      group_ids: nil, user_ids: [ gws_user.id ]
    )
  end

  # 個人
  let!(:minimum_role) do
    create :gws_role, cur_site: site, permissions: %w(read_private_gws_workflow2_routes edit_private_gws_workflow2_routes)
  end
  let(:group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let(:user) do
    create :gws_user, gws_role_ids: [ minimum_role.id ], group_ids: [ group.id ]
  end
  let(:name) { unique_id }

  before do
    login_user user
  end

  it do
    visit gws_workflow2_routes_path(site: site)
    within ".list-items" do
      # この画面では管理可能な承認ルートの一覧が表示されているが、現在、管理可能なものはゼロ
      expect(page).to have_no_css(".list-item")
    end
    within ".nav-menu" do
      click_on I18n.t('ss.links.copy')
    end
    within ".list-items" do
      # この画面では閲覧可能な承認ルートの一覧が表示されており、管理者が作成した承認ルートは全公開に設定されているため、一覧に表示されている
      click_on route0.name
    end
    within "form#item-form" do
      fill_in "item[name]", with: name
      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    route = Gws::Workflow2::Route.find_by(name: name)
    expect(route.site_id).to eq site.id
    expect(route.name).to eq name
    expect(route.approvers).to eq route0.approvers
    expect(route.circulations).to eq route0.circulations
    expect(route.group_ids).to be_blank
    expect(route.user_ids).to eq [ user.id ]
  end
end
