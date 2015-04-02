require 'spec_helper'

describe "Article::PagesController", type: :request, dbscope: :example do
  let!(:group) { cms_group }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create(:article_node_page) }
  let(:auth_token_path) { sns_auth_token_path(format: :json) }
  let(:index_path) { article_pages_path(site.host, node, format: :json) }

  before do
    # get and save  auth token
    get auth_token_path
    @auth_token = JSON.parse(response.body)["auth_token"]

    # login
    params = { 'authenticity_token' => @auth_token, 'item[email]' => user.email, 'item[password]' => user.in_password }
    post sns_login_path(format: :json), params
  end

  describe "GET /pages.json" do
    let!(:page) { create(:article_page, filename: "#{node.filename}/filename#{rand(0xffffffff).to_s(36)}") }

    it do
      get index_path
      expect(response.status).to eq 200
      list = JSON.parse(response.body)
      expect(list.length).to eq 1
      expect(list[0]["_id"]).to eq 1
      expect(list[0]["name"]).to eq page.name
      expect(list[0]["filename"]).to eq page.filename
    end
  end

  describe "POST /pages.json" do
    it do
      params = { 'authenticity_token' => @auth_token,
                 'item[name]' => '記事タイトル',
                 'item[basename]' => "filename#{rand(0xffffffff).to_s(36)}" }
      post index_path, params
      expect(response.status).to eq 201
      page = JSON.parse(response.body)
      expect(page["_id"]).to eq 1
      expect(page["name"]).to eq params['item[name]']
      expect(page["filename"]).to eq "#{node.filename}/#{params['item[basename]']}.html"
    end
  end
end
