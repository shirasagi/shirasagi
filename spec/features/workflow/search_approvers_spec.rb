require 'spec_helper'

describe "workflow_search_approvers" do
  subject(:site) { cms_site }
  subject(:user) { cms_user }
  subject(:group) { cms_group }
  subject(:index_path) { workflow_search_approvers_path site.host }

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

    it "#index" do
      visit index_path
      # save_and_open_page
      # print page.html
      within("form.search") do
        expect(all("option").reduce([]) { |a, e| a << e.value }).to include "#{group.id}"
      end
      within("table.index") do
        expect(find("a.select-item").text).to eq "#{user.long_name}"
      end

      expect(current_path).not_to eq sns_login_path
    end
  end

end
