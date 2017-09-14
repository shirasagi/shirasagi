require 'spec_helper'

describe "gws_schedule_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:group) { gws_user.groups.first }
  let(:index_path) { gws_schedule_all_groups_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end
