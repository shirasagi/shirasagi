require 'spec_helper'

describe "sns_remote_login", dbscope: :example do
  let(:login_path) { sns_remote_login_path }

  context "remote_off" do
    before do
      SS.config.replace_value_at :sns, :remote_login, false
    end

    it "invalid" do
      visit login_path
      expect(status_code).to eq 404
    end
  end

  context "remote_on" do
    before do
      SS.config.replace_value_at :sns, :remote_login, true
    end

    it "valid" do
      visit login_path
      expect(status_code).to eq 200
    end
  end

  after do
    SS.config.replace_value_at :sns, :remote_login, false
  end
end
