require 'spec_helper'

describe "member_logins", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :member_node_login, site: cms_site }
  let(:index_path) { member_logins_path site.id, node.id }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        within "article#main" do
          # empty content
        end
      end
    end
  end
end
