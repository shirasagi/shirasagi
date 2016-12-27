require 'spec_helper'

describe "webmail_signatures", type: :feature, dbscope: :example do
  let(:item) { create :webmail_signature }
  let(:index_path) { webmail_signatures_path }
  let(:new_path) { "#{index_path}/new" }
  let(:show_path) { "#{index_path}/#{item.id}" }
  let(:edit_path) { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }

  context "with auth" do
    before { login_ss_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
    end

    it "#new" do
      visit new_path
      expect(status_code).to eq 200
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
    end

    it "#edit" do
      visit edit_path
      expect(status_code).to eq 200
    end

    it "#delete" do
      visit delete_path
      expect(status_code).to eq 200
    end
  end
end
