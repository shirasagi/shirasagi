require 'spec_helper'

describe "opendata_agents_parts_mypage_login", dbscope: :example do
  let(:site) { cms_site }
  let!(:parts) { create(:opendata_part_mypage_login) }
  let(:index_path) { parts.url }

  it "#index" do
    page.driver.browser.with_session("public") do |session|
      session.env("HTTP_X_FORWARDED_HOST", site.domain)
      session.env("REQUEST_PATH", index_path)
      visit index_path
      expect(current_path).to eq index_path
    end
  end
end
