require 'spec_helper'

describe "authes", dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :opendata_node_mypage, filename: "mypage", basename: "mypage" }

  let(:dataset_url) { ::URI.parse "http://#{site.domain}#{node.url}dataset/" }
  let(:provide_url) { ::URI.parse "http://#{site.domain}#{node.url}twitter" }
  let(:login_path) { "#{node.url}login" }

  context "oauth_fail" do
    let!(:oauth_fail) { fail_omniauth(:twitter) }

    it "#fail" do
      visit provide_url
      expect(current_path).to eq login_path
    end
  end

  context "oauth_callback create_member" do
    let!(:oauth_user) { set_omniauth }

    it "#callback" do
      visit provide_url
      expect(current_path).to eq dataset_url.path
    end
  end

  context "oauth_callback get_member" do
    let!(:member) { opendata_member(site: site, oauth_type: :twitter, oauth_id: "1234") }
    let!(:oauth_user) { set_omniauth(member) }

    it "#callback" do
      visit provide_url
      expect(current_path).to eq dataset_url.path
    end
  end
end
