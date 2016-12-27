require 'spec_helper'

describe "workflow_search_approvers", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:group) { cms_group }
  let(:index_path) { workflow_search_approvers_path site.id }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      within("table.index tbody.items") do
        expect(find("a.select-item").text).to eq user.long_name.to_s
      end

      expect(current_path).not_to eq sns_login_path
    end
  end

end
