require 'spec_helper'

describe "authes" do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_mypage, basename: "opendata/mypage" }
  let(:oauth_user) { set_omniauth(:twitter) }
  let(:provide_path) { "#{node.url}twitter" }

  before do
    opendata_member(site, :twitter, "1234")
  end

  context "member" do
    it "#provide" do
      page.driver.browser.with_session("public") do |session|
        session.env("HTTP_X_FORWARDED_HOST", site.domain)
        session.env("REQUEST_PATH", provide_path)
        session.env("omniauth.auth", oauth_user)
        visit "http://#{site.domain}#{provide_path}"
        expect(current_path).to eq "/mypage/"
      end
    end
  end
end
