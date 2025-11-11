require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20251003000000_update_redirect_link_setting.rb")

RSpec.describe SS::Migration20251003000000, dbscope: :example do
  let(:site1) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }
  let(:site2) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }
  let(:site3) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }

  context "not exists cms.yml setting" do
    it do
      expect(site1.redirect_link_enabled?).to be_falsey
      expect(site2.redirect_link_enabled?).to be_falsey
      expect(site3.redirect_link_enabled?).to be_falsey

      described_class.new.change

      site1.reload
      site2.reload
      site3.reload

      expect(site1.redirect_link_enabled?).to be_falsey
      expect(site2.redirect_link_enabled?).to be_falsey
      expect(site3.redirect_link_enabled?).to be_falsey
    end
  end

  context "exists cms.yml setting" do
    before do
      @disable_redirect_link = SS.config.cms.disable_redirect_link
      SS.config.replace_value_at(:cms, :disable_redirect_link, false)
    end

    after do
      SS.config.replace_value_at(:cms, :disable_redirect_link, @disable_redirect_link)
    end

    it do
      expect(site1.redirect_link_enabled?).to be_falsey
      expect(site2.redirect_link_enabled?).to be_falsey
      expect(site3.redirect_link_enabled?).to be_falsey

      described_class.new.change

      site1.reload
      site2.reload
      site3.reload

      expect(site1.redirect_link_enabled?).to be_truthy
      expect(site2.redirect_link_enabled?).to be_truthy
      expect(site3.redirect_link_enabled?).to be_truthy
    end
  end
end
