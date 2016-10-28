require 'spec_helper'

describe "webapi", dbscope: :example, type: :request do
  before do
    SS.config.replace_value_at(:env, :protect_csrf, false)
  end

  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create(:article_node_page) }
  let!(:item) { create(:article_page, cur_node: node) }
  let!(:layout) { create(:cms_layout) }
  let!(:body_layout) { create(:cms_body_layout) }

  ## paths
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:logout_path) { sns_logout_path(format: :json) }
  let!(:preview_path) { cms_preview_path(site: site.id, path: item.filename) }
  let!(:form_preview_path) { cms_form_preview_path(site: site.id, path: "#{item.parent.filename}/.html") }

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
          params = { preview_item: { id: item.id } }
          post form_preview_path, params
          expect(response.status).to eq 200
        end

        it "200 with page id" do
          params = { preview_item: {
            id: item.id,
            layout_id: layout.id,
            body_layout_id: body_layout.id,
            body_parts: %w(パーツ１ パーツ２ パーツ３),
          } }

          post form_preview_path, params
          expect(response.status).to eq 200

          expect(response.body.include?('パーツ１')).to be_truthy
          expect(response.body.include?('パーツ２')).to be_truthy
          expect(response.body.include?('パーツ３')).to be_truthy
          expect(response.body.include?('<div id="ss-preview">')).to be_truthy
          expect(response.body.include?('<input type="button" class="preview" value="PC">')).to be_truthy
          expect(response.body.include?('<input type="button" class="mobile" value="携帯">')).to be_truthy
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
