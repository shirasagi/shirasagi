require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20200221000000_set_gws_staff_record_user_titles.rb")

RSpec.describe SS::Migration20200221000000, dbscope: :example do
  let(:user_title_name) { unique_id }
  let(:sr_year) { create :gws_staff_record_year }
  let(:sr_group) { create :gws_staff_record_group, year_id: sr_year.id }
  let(:sr_user) { create :gws_staff_record_user, year_id: sr_year.id, section_name: sr_group.name }

  before do
    sr_user[:title_name] = user_title_name
    sr_user.save!
  end

  context 'without user_title' do
    before do
      described_class.new.change
    end

    it 'sr_user should not be have title_ids' do
      sr_user.reload
      expect(sr_user.title).to be_nil
    end
  end

  context 'with active user_title' do
    let!(:user_title) { create :gws_user_title, name: user_title_name }

    before do
      described_class.new.change
    end

    it 'sr_user should be have title_ids' do
      sr_user.reload
      expect(sr_user.title).to be_present
      expect(sr_user.title.name).to eq user_title_name
      expect(sr_user.title.code).to eq user_title.code
      expect(sr_user.title.activation_date).to eq user_title.activation_date
      expect(sr_user.title.expiration_date).to eq user_title.expiration_date
      expect(sr_user.title.remark).to eq user_title.remark
    end
  end

  context 'with expired user_title' do
    let!(:user_title) { create :gws_user_title, name: user_title_name, expiration_date: Time.zone.yesterday }

    before do
      described_class.new.change
    end

    it 'sr_user should not be have title_ids' do
      sr_user.reload
      expect(sr_user.title).to be_nil
    end
  end

  context 'with active sr_user_title' do
    let!(:sr_user_title) { create :gws_staff_record_user_title, year_id: sr_year.id, name: user_title_name }

    before do
      described_class.new.change
    end

    it 'sr_user should be have title_ids' do
      sr_user.reload
      expect(sr_user.title).to eq sr_user_title
    end
  end

  context 'with expired sr_user_title' do
    let!(:sr_user_title) do
      create :gws_staff_record_user_title, year_id: sr_year.id, name: user_title_name, expiration_date: Time.zone.yesterday
    end

    before do
      described_class.new.change
    end

    it 'sr_user should not be have title_ids' do
      sr_user.reload
      expect(sr_user.title).to be_nil
    end
  end
end
