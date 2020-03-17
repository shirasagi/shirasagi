require 'spec_helper'

describe "opendata_agents_nodes_my_idea", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let!(:node) { create :opendata_node_idea, cur_site: cms_site, layout_id: layout.id }
  let!(:member) { create :opendata_node_member, cur_site: cms_site, layout_id: layout.id }

  let!(:upper_html) { "<a href=\"new/\">#{I18n.t("ss.links.new")}</a>" }
  let!(:node_mypage) { create :opendata_node_mypage, cur_site: cms_site, layout_id: layout.id, filename: "mypage" }
  let!(:node_myidea) do
    create :opendata_node_my_idea, cur_site: cms_site, cur_node: node_mypage, layout_id: layout.id, upper_html: upper_html
  end
  let!(:node_login) { create :member_node_login, cur_site: cms_site, layout_id: layout.id, redirect_url: node_myidea.url }

  let(:node_category_folder) { create(:cms_node_node, cur_site: cms_site, layout_id: layout.id) }
  let!(:category) do
    create(
      :opendata_node_category,
      cur_site: cms_site,
      cur_node: node_category_folder,
      layout_id: layout.id,
      name: "カテゴリー０１")
  end
  let!(:area) { create :opendata_node_area, cur_site: cms_site, layout_id: layout.id, name: "地域Ａ" }
  let(:node_idea) { create :opendata_node_idea, cur_site: cms_site, layout_id: layout.id }

  let!(:node_search) { create :opendata_node_search_idea }

  let(:index_path) { "#{node_myidea.url}index.html" }

  let(:item_name) { "アイデア０１" }
  let(:item_name2) { "アイデア０２" }
  let(:item_text) { "アイデア内容" }

  let(:save) { I18n.t("ss.buttons.publish_save") }
  let(:edit) { I18n.t("ss.buttons.edit") }
  let(:delete) { I18n.t('ss.buttons.delete') }

  before do
    login_opendata_member(site, node_login)
  end

  after do
    logout_opendata_member(site, node_login)
  end

  it "basic crud" do
    visit index_path
    expect(current_path).to eq index_path

    click_link I18n.t('ss.links.new')
    fill_in "item_name", with: item_name
    fill_in "item_text", with: item_text
    check category.name
    click_button save

    expect(current_path).to eq node_myidea.url
    expect(page).to have_link(item_name)

    click_link item_name
    expect(page).to have_link(edit)

    click_link edit
    fill_in "item_name", with: item_name2
    expect(page).to have_button(save)

    click_button save
    expect(page).to have_link(delete)

    click_link delete
    expect(page).to have_button(delete)

    click_button delete
    expect(current_path).to eq node_myidea.url
  end

  context "when workflow is enabled" do
    let(:remand_comment) { unique_id }

    before do
      workflow = create :workflow_route

      site.dataset_workflow_route_id = workflow.id
      site.app_workflow_route_id = workflow.id
      site.idea_workflow_route_id = workflow.id
      site.save!
    end

    before do
      ActionMailer::Base.deliveries = []
    end

    after do
      ActionMailer::Base.deliveries = []
    end

    it do
      visit index_path
      click_link I18n.t('ss.links.new')

      fill_in "item_name", with: item_name
      fill_in "item_text", with: item_text
      check category.name
      click_button I18n.t("ss.buttons.request")

      expect(page).to have_css("#ss-notice", text: I18n.t('ss.notice.saved'))

      click_link item_name
      expect(page).to have_css(".status .input", text: I18n.t("ss.options.state.request"))

      expect(Opendata::Idea.count).to eq 1
      Opendata::Idea.first.tap do |idea|
        expect(idea.name).to eq item_name
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.to.first).to eq cms_user.email
        expect(mail.subject).to eq "[#{I18n.t('workflow.mail.subject.request')}]#{item_name} - #{site.name}"
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(opendata_member(site: site).name)
        expect(mail.body.raw_source).to include(item_name)
        expect(mail.body.raw_source).to include(Opendata::Idea.first.private_show_path)
      end

      login_cms_user
      visit Opendata::Idea.first.private_show_path
      within "#addon-basic" do
        expect(page).to have_css("dd", text: item_name)
      end
      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment
        click_on I18n.t("workflow.buttons.approve")
      end

      login_opendata_member(site, node_login)
      visit index_path
      click_link item_name
      expect(page).to have_css(".status .input", text: I18n.t("ss.options.state.public"))
      expect(page).to have_css(".workflow-comment .input", text: remand_comment)
    end
  end
end
