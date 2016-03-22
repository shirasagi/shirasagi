require 'spec_helper'

describe "webapi", dbscope: :example, type: :request do
  before do
    SS.config.replace_value_at(:env, :protect_csrf, false)
  end

  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create(:article_node_page) }
  let!(:page) { create(:article_page, cur_node: node) }

  ## paths
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:logout_path) { sns_logout_path(format: :json) }
  let!(:preview_path) { cms_preview_path(site: site.id, path: page.filename) }
  let!(:form_preview_path) { cms_form_preview_path(site: site.id, path: "#{page.parent.filename}/.html") }

  ## request params
  let!(:correct_login_params) do
    {
      :item => {
        :email => user.email,
        :password => SS::Crypt.encrypt("pass", type: "AES-256-CBC"),
        :encryption_type => "AES-256-CBC"
      }
    }
  end

  context "with login" do
    before { post login_path, correct_login_params }

    context "preview" do
      describe "GET /.s{site}/preview/{path}" do
        it "200" do
          get preview_path
          expect(response.status).to eq 200
        end
      end
    end

    context "form preview" do
      describe "POST /.s{site}/preview/{path}" do
        it "200" do
          preview_page          = Cms::Page.new page.attributes
          preview_page.name     = "preview test"
          preview_page.basename = "preview_test.html"

          params = { preview_item: { id: preview_page.id } }
          post form_preview_path, params
          expect(response.status).to eq 200
        end

        #it "400" do
        #  params = {}
        #  post form_preview_path, params
        #  expect(response.status).to eq 400
        #end
      end
    end
  end
end
