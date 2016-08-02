require 'spec_helper'

describe "opendata_agents_nodes_my_dataset", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:member) { opendata_member(site: site) }
  let!(:node_member) { create :opendata_node_member, cur_site: site, layout_id: layout.id }
  let!(:node_dataset) { create :opendata_node_dataset, cur_site: site, layout_id: layout.id }
  let!(:node_search_dataset) do
    create :opendata_node_search_dataset, cur_site: site, cur_node: node_dataset, layout_id: layout.id
  end

  let!(:upper_html) { '<a href="new/">新規作成</a><table class="opendata-datasets datasets"><tbody>' }
  let!(:node_mypage) { create :opendata_node_mypage, cur_site: site, layout_id: layout.id, filename: "mypage" }
  let!(:node_my_dataset) do
    create :opendata_node_my_dataset, cur_site: site, cur_node: node_mypage, layout_id: layout.id, upper_html: upper_html
  end

  let!(:node_login) { create :member_node_login, cur_site: site, layout_id: layout.id, redirect_url: node_my_dataset.url }

  let(:node_category_folder) { create(:cms_node_node, cur_site: site, layout_id: layout.id, basename: "category") }
  let!(:category) do
    create(
      :opendata_node_category,
      cur_site: site,
      cur_node: node_category_folder,
      layout_id: layout.id,
      name: "カテゴリー０１")
  end
  let!(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id, name: "地域Ａ" }

  let!(:node_search) { create :opendata_node_search_dataset, cur_site: site, layout_id: layout.id }

  let(:index_url) { ::URI.parse "http://#{site.domain}#{node_my_dataset.url}" }

  let(:item_name) { "データセット０１" }
  let(:item_name2) { "データセット０２" }
  let(:item_text) { "データセット内容" }

  before do
    login_opendata_member(site, node_login, member)
  end

  after do
    logout_opendata_member(site, node_login, member)
  end

  describe "#index" do
    let!(:dataset) { create :opendata_dataset, cur_node: node_dataset, member_id: member.id }

    it do
      visit index_url
      expect(current_path).to eq index_url.path
      expect(status_code).to eq 200
      within "table.opendata-datasets" do
        expect(page).to have_content dataset.name
      end
    end
  end

  it "#new_create_edit_delete" do
    visit index_url
    click_link "新規作成"
    expect(status_code).to eq 200

    fill_in "item_name", with: item_name
    fill_in "item_text", with: item_text
    check category.name
    click_button "公開保存"
    expect(status_code).to eq 200

    within "table.opendata-datasets" do
      expect(page).to have_content item_name
    end

    click_link item_name
    expect(status_code).to eq 200

    within "table.opendata-dataset" do
      expect(page).to have_content item_name
      expect(page).to have_content item_text
      expect(page).to have_content category.name
    end

    click_link "編集"
    expect(status_code).to eq 200
    within "form#item-form" do
      fill_in "item_name", with: item_name2
    end

    click_button "公開保存"
    expect(status_code).to eq 200

    within "table.opendata-dataset" do
      expect(page).to have_content item_name2
      expect(page).to have_content item_text
      expect(page).to have_content category.name
    end

    click_link "削除"
    click_button "削除"
    expect(status_code).to eq 200
    expect(current_path).to eq index_url.path

    within "table.opendata-datasets" do
      expect(page).not_to have_content item_name2
    end
  end

  context "when workflow is enabled" do
    let(:resource_file) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let(:resource_name) { unique_id }
    let(:resource_format) { 'PNG' }
    let(:resource_text) { unique_id }
    let(:license_file) { Fs::UploadedFile.create_from_file(resource_file, basename: "spec") }
    let!(:license) { create :opendata_license, cur_site: site, in_file: license_file }
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
      visit index_url
      click_link "新規作成"
      expect(status_code).to eq 200

      fill_in "item_name", with: item_name
      fill_in "item_text", with: item_text
      check category.name
      click_button "非公開保存"
      expect(status_code).to eq 200

      click_link item_name
      click_link 'リソースを管理する'
      click_link '新規作成'
      attach_file "item[in_file]", resource_file
      fill_in "item[name]", with: resource_name
      fill_in "item[format]", with: resource_format
      select license.name, from: "item[license_id]"
      fill_in "item[text]", with: resource_text
      click_button '公開申請'

      expect(page).to have_css("#ss-notice", text: "保存しました。")

      visit index_url
      click_link item_name
      expect(page).to have_css(".status .input", text: "申請")

      expect(Opendata::Dataset.count).to eq 1
      Opendata::Dataset.first.tap do |dataset|
        expect(dataset.name).to eq item_name
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.to.first).to eq cms_user.email
        expect(mail.subject).to eq "[承認申請]#{item_name} - #{site.name}"
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(member.name)
        expect(mail.body.raw_source).to include(item_name)
        expect(mail.body.raw_source).to include(Opendata::Dataset.first.private_show_path)
      end

      login_cms_user
      visit Opendata::Dataset.first.private_show_path
      within "#addon-basic" do
        expect(page).to have_css("dd", text: item_name)
      end
      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment
        click_on "承認"
      end

      visit index_url
      click_link item_name
      expect(page).to have_css(".status .input", text: "公開")
      expect(page).to have_css(".workflow-comment .input", text: remand_comment)
    end
  end
end
