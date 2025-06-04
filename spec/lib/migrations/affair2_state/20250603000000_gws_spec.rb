require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20250603000000_affair2_state.rb")

RSpec.describe SS::Migration20250603000000, dbscope: :example do
  let!(:site) { gws_site }

  context "when menu_affair_state is nil" do
    it do
      expect(site.menu_visible?(:affair)).to be_falsey
      expect(site.menu_visible?(:affair2)).to be_truthy

      described_class.new.change
      site.reload

      expect(site.menu_visible?(:affair)).to be_falsey
      expect(site.menu_visible?(:affair2)).to be_truthy
    end
  end

  context "when menu_affair_state is show" do
    it do
      site.menu_affair_state = "show"
      site.update!

      expect(site.menu_visible?(:affair)).to be_truthy
      expect(site.menu_visible?(:affair2)).to be_truthy

      described_class.new.change
      site.reload

      expect(site.menu_visible?(:affair)).to be_falsey
      expect(site.menu_visible?(:affair2)).to be_truthy
    end
  end

  context "when menu_affair2_state is hide" do
    it do
      site.menu_affair2_state = "hide"
      site.update!

      expect(site.menu_visible?(:affair)).to be_falsey
      expect(site.menu_visible?(:affair2)).to be_falsey

      described_class.new.change
      site.reload

      expect(site.menu_visible?(:affair)).to be_falsey
      expect(site.menu_visible?(:affair2)).to be_falsey
    end
  end
end
