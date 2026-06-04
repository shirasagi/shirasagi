require 'spec_helper'

describe "sys_test", type: :feature, dbscope: :example do
  context "without auth" do
    it do
      login_ss_user to: sys_diag_main_path
      expect(page).to have_title(/403 Forbidden/)
    end
  end

  context "with auth" do
    it do
      login_sys_user to: sys_diag_main_path
      expect(current_path).to eq sys_diag_mails_path
    end
  end
end
