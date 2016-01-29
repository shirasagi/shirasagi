require 'spec_helper'

describe "opendata_agents_nodes_my_app", dbscope: :example do
  def create_appfile(app, file, format)
    appfile = app.appfiles.new(text: "aaa", format: format)
    appfile.in_file = file
    appfile.save
    appfile
  end

  let(:site) { cms_site }
  let!(:node) { create_once :opendata_node_app, name: "opendata_agents_nodes_my_app" }
  let!(:node_member) { create_once :opendata_node_member }
  let!(:node_mypage) { create_once :opendata_node_mypage, filename: "mypage" }
  let!(:node_myapp) { create_once :opendata_node_my_app, filename: "#{node_mypage.filename}/app" }
  let!(:node_login) { create :member_node_login, redirect_url: node_myapp.url }
  let!(:node_dataset) { create_once :opendata_node_dataset }

  let!(:node_search) { create :opendata_node_search_app }

  let(:node_category_folder) { create_once(:cms_node_node, basename: "category") }
  let!(:category) do
    create_once(
      :opendata_node_category,
      name: "カテゴリー",
      filename: "#{node_category_folder.filename}/#{unique_id}",
      depth: node_category_folder.depth + 1)
  end
  let!(:app) { create_once :opendata_app, filename: "#{node.filename}/1.html", member_id: "1" }
  let!(:file_path) { Rails.root.join("spec", "fixtures", "opendata", "utf-8.csv") }
  let!(:file) { Fs::UploadedFile.create_from_file(file_path, basename: "spec") }
  let!(:appfile) { create_appfile(app, file, "CSV") }

  let!(:node_auth) { create_once :opendata_node_mypage, basename: "opendata/mypage" }

  let(:index_path) { "#{node_myapp.url}" }
  let(:new_path) { "#{node_myapp.url}new/" }
  let(:show_path) { "#{node_myapp.url}#{app.id}/" }
  let(:edit_path) { "#{node_myapp.url}#{app.id}/edit/" }
  let(:delete_path) { "#{node_myapp.url}#{app.id}/delete/" }

  before do
    login_opendata_member(site, node_login)
  end

  after do
    logout_opendata_member(site, node_login)
  end

  it "#index" do
    visit "http://#{site.domain}#{index_path}"
    expect(current_path).to eq index_path
  end

  it "#new" do
    visit "http://#{site.domain}#{new_path}"
    expect(current_path).to eq new_path
    within "form#item-form" do
      fill_in "item[name]", with: "あぷり"
      fill_in "item[text]", with: "せつめい"
      fill_in "item[license]", with: "MIT"
      check category.name
      click_on "公開保存"
    end
    expect(current_path).to eq index_path
  end

  it "#new error" do
    visit "http://#{site.domain}#{new_path}"
    expect(current_path).to eq new_path
    within "form#item-form" do
      click_on "公開保存"
    end
    expect(current_path).to eq index_path
  end

  it "#show" do
    visit "http://#{site.domain}#{show_path}"
    expect(current_path).to eq show_path
  end

  it "#edit" do
    visit "http://#{site.domain}#{edit_path}"
    expect(current_path).to eq edit_path
    within "form#item-form" do
      fill_in "item[name]", with: "あぷり"
      fill_in "item[text]", with: "こうしん"
      fill_in "item[license]", with: "MIT"
      check category.name
      click_on "公開保存"
    end
    expect(current_path).to eq show_path
  end

  it "#edit error" do
    visit "http://#{site.domain}#{edit_path}"
    expect(current_path).to eq edit_path
    within "form#item-form" do
      click_on "公開保存"
    end
    expect("#{current_path}").to eq show_path
  end

  it "#delete" do
    visit "http://#{site.domain}#{delete_path}"
    expect(current_path).to eq delete_path
    within "form" do
      click_on I18n.t("views.button.delete")
    end
    expect(current_path).to eq index_path
  end
end
