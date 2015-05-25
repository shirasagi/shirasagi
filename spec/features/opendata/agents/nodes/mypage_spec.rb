require 'spec_helper'

describe "authes" do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_mypage, basename: "opendata/mypage" }
  let(:oauth_user) { set_omniauth(site, :twitter) }
  let(:provide_path) { "#{node.url}#{oauth_user.provider}" }

  it "#provide" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", provide_path)
      visit provide_path
      expect(current_path).to eq "/mypage/"
    end
  end
end
