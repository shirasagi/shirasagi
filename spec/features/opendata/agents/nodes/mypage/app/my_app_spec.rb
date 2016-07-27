require 'spec_helper'

describe "opendata_agents_nodes_my_app", dbscope: :example do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "aaa", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:site) { cms_site }
  let(:member) { opendata_member(site: site) }
  let!(:node) { create :opendata_node_app, name: "opendata_agents_nodes_my_app" }
  let!(:node_member) { create :opendata_node_member }
  let!(:node_mypage) { create :opendata_node_mypage, filename: "mypage" }
  let!(:upper_html) { '<a href="new/">新規作成</a><table class="opendata-app apps"><tbody>' }
  let!(:node_myapp) { create :opendata_node_my_app, cur_node: node_mypage, filename: "app", upper_html: upper_html }
  let!(:node_login) { create :member_node_login, redirect_url: node_myapp.url }
  let!(:node_dataset) { create :opendata_node_dataset }

  let!(:node_search) { create :opendata_node_search_app }

  let(:node_category_folder) { create(:cms_node_node, basename: "category") }
  let!(:category) do
    create(
      :opendata_node_category,
      cur_node: node_category_folder,
      name: "カテゴリー",
      filename: unique_id)
  end

  let!(:node_auth) { create :opendata_node_mypage, basename: "opendata/mypage" }

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
end
