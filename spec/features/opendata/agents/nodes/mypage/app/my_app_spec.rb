require 'spec_helper'

describe "opendata_agents_nodes_my_app", dbscope: :example, js: true do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "aaa", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:site) { cms_site }
  let(:layout) { create_cms_layout }
  let(:member) { opendata_member(site: site) }
  let!(:node) { create :opendata_node_app, cur_site: site, layout_id: layout.id, name: "opendata_agents_nodes_my_app" }
  let!(:node_member) { create :opendata_node_member, cur_site: site, layout_id: layout.id }
  let!(:node_mypage) { create :opendata_node_mypage, cur_site: site, layout_id: layout.id, filename: "mypage" }
  let!(:upper_html) { '<a href="new/">新規作成</a><table class="opendata-app apps"><tbody>' }
  let!(:node_myapp) do
    create(:opendata_node_my_app, cur_site: site, cur_node: node_mypage, layout_id: layout.id, upper_html: upper_html)
  end
  let!(:node_login) { create :member_node_login, cur_site: site, layout_id: layout.id, redirect_url: node_myapp.url }
  let!(:node_dataset) { create :opendata_node_dataset, cur_site: site, layout_id: layout.id }

  let!(:node_search) { create :opendata_node_search_app, cur_site: site, layout_id: layout.id }

  let(:node_category_folder) { create(:cms_node_node, cur_site: site, layout_id: layout.id, basename: "category") }
  let!(:category) do
    create(
      :opendata_node_category,
      cur_site: site,
      cur_node: node_category_folder,
      layout_id: layout.id,
      name: "カテゴリー")
  end

  let!(:node_auth) { create :opendata_node_mypage, cur_site: site, layout_id: layout.id, basename: "opendata/mypage" }

  let(:index_path) { node_myapp.url }

  before do
    login_opendata_member(site, node_login, member)
  end

  after do
    logout_opendata_member(site, node_login, member)
  end

  describe "basic crud" do
    it do
      visit "http://#{site.domain}#{index_path}"
      expect(current_path).to eq index_path

      click_link "新規作成"
      within "form#item-form" do
        fill_in "item[name]", with: "あぷり"
        fill_in "item[text]", with: "せつめい"
        fill_in "item[license]", with: "MIT"
        check category.name
        click_on "公開保存"
      end
      expect(current_path).to eq index_path

      click_link "あぷり"
      expect(status_code).to eq 200

      within "table.opendata-app" do
        expect(page).to have_content "あぷり"
        expect(page).to have_content "せつめい"
        expect(page).to have_content "MIT"
      end

      click_link "編集"
      expect(status_code).to eq 200
      within "form#item-form" do
        fill_in "item[name]", with: "あぷり2"
        fill_in "item[text]", with: "こうしん"
        fill_in "item[license]", with: "GPL"
        check category.name
        click_on "公開保存"
      end
      expect(status_code).to eq 200

      within "table.opendata-app" do
        expect(page).to have_content "あぷり2"
        expect(page).to have_content "こうしん"
        expect(page).to have_content "GPL"
      end

      click_link "削除"
      click_button "削除"
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      within "table.opendata-app" do
        expect(page).not_to have_content "あぷり2"
      end
    end
  end

  describe "new error" do
    it do
      visit "http://#{site.domain}#{index_path}"
      click_link "新規作成"
      within "form#item-form" do
        click_on "公開保存"
      end
      expect(page).to have_css('#errorExplanation', text: '登録内容を確認してください。')
    end
  end

  describe "edit error" do
    let!(:app) { create :opendata_app, cur_node: node, filename: "1.html", member_id: member.id }
    let!(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
    let!(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
    let!(:appfile) { create_appfile(app, file, "CSV") }

    let(:edit_path) { "#{node_myapp.url}#{app.id}/edit/" }

    it do
      visit "http://#{site.domain}#{index_path}"
      click_link app.name
      click_link "編集"

      within "form#item-form" do
        fill_in "item[name]", with: ""
        click_on "公開保存"
      end

      expect(page).to have_css('#errorExplanation', text: '登録内容を確認してください。')
    end
  end

  context "when workflow is enabled" do
    let(:item_name) { unique_id }
    let(:item_text) { unique_id }
    let(:item_license) { unique_id }
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
      visit "http://#{site.domain}#{index_path}"
      expect(current_path).to eq index_path

      click_link "新規作成"
      within "form#item-form" do
        fill_in "item[name]", with: item_name
        fill_in "item[text]", with: item_text
        fill_in "item[license]", with: item_license
        check category.name
        click_on "公開申請"
      end
      expect(page).to have_css("#ss-notice", text: "保存しました。")

      click_link item_name
      expect(page).to have_css(".name .input", text: item_name)
      expect(page).to have_css(".text .input", text: item_text)
      expect(page).to have_css(".license .input", text: item_license)
      expect(page).to have_css(".status .input", text: "申請")

      expect(Opendata::App.count).to eq 1
      Opendata::App.first.tap do |app|
        expect(app.name).to eq item_name
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |mail|
        expect(mail.to.first).to eq cms_user.email
        expect(mail.subject).to eq "[承認申請]#{item_name} - #{site.name}"
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include(member.name)
        expect(mail.body.raw_source).to include(item_name)
        expect(mail.body.raw_source).to include(Opendata::App.first.private_show_path)
      end

      login_cms_user
      visit Opendata::App.first.private_show_path
      within "#addon-basic" do
        expect(page).to have_css("dd", text: item_name)
      end
      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment
        click_on "承認"
      end

      visit "http://#{site.domain}#{index_path}"
      click_link item_name
      expect(page).to have_css(".status .input", text: "公開")
      expect(page).to have_css(".workflow-comment .input", text: remand_comment)
    end
  end
end
