require 'spec_helper'

describe "webapi body_layout", dbscope: :example, type: :request do
  before do
    SS.config.replace_value_at(:env, :protect_csrf, false)
  end

  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:item) { create(:cms_body_layout, site: cms_site, user: cms_user) }

  ## paths
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:logout_path) { sns_logout_path(format: :json) }
  let!(:body_layout_path) { cms_body_layout_path(site: site, id: item.id, format: :json) }

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

    describe "GET /.s{site}/cms/body_layouts/{id}.json" do
      it "200" do
        get body_layout_path
        expect(response.status).to eq 200

        json = JSON.parse(response.body)
        expect(json["_id"]).to eq item.id
        expect(json["name"]).to eq item.name
        expect(json["parts"]).to eq item.parts
        expect(json["html"]).to eq item.html
      end
    end
  end
end
