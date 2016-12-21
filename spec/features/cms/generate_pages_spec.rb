require 'spec_helper'

describe "cms_generate_pages" do
  subject(:site) { cms_site }
  subject(:index_path) { cms_generate_pages_path site.id }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end
