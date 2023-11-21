require 'spec_helper'
require Rails.root.join("lib/migrations/contact/20221109000000_multi_contacts_on_group.rb")

RSpec.describe SS::Migration20221109000000, dbscope: :example do
  let(:contact_group_name1) { unique_id }
  let(:contact_charge1) { unique_id }
  let(:contact_tel1) { unique_tel }
  let(:contact_fax1) { unique_tel }
  let(:contact_email1) { unique_email }
  let(:contact_link_url1) { unique_url }
  let(:contact_link_name1) { unique_id }
  let!(:group1) { create(:cms_group, name: unique_id) }

  before do
    group1.unset(:contact_groups)
    group1.set(
      contact_group_name: contact_group_name1, contact_charge: contact_charge1,
      contact_tel: contact_tel1, contact_fax: contact_fax1,
      contact_email: contact_email1, contact_link_url: contact_link_url1, contact_link_name: contact_link_name1)

    described_class.new.change
  end

  it do
    group1.reload
    expect(group1.contact_groups.count).to eq 1
    group1.contact_groups.first.tap do |contact_group|
      expect(contact_group.contact_group_name).to eq contact_group_name1
      expect(contact_group.contact_charge).to eq contact_charge1
      expect(contact_group.contact_tel).to eq contact_tel1
      expect(contact_group.contact_fax).to eq contact_fax1
      expect(contact_group.contact_email).to eq contact_email1
      expect(contact_group.contact_link_url).to eq contact_link_url1
      expect(contact_group.contact_link_name).to eq contact_link_name1
      expect(contact_group.main_state).to eq "main"
    end
  end
end
