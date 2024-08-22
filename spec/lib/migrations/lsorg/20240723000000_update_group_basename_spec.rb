require 'spec_helper'
require Rails.root.join("lib/migrations/lsorg/20240723000000_update_group_basename.rb")

RSpec.describe SS::Migration20240723000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group1) { create :cms_group, name: unique_id }
  let!(:group2) { create :cms_group, name: unique_id }

  it do
    group1.unset(:basename)
    group2.unset(:basename)

    group1.reload
    group2.reload

    expect(group1.basename).to be_blank
    expect(group2.basename).to be_blank

    described_class.new.change

    group1.reload
    group2.reload

    expect(group1.basename).to eq "g#{group1.id}"
    expect(group2.basename).to eq "g#{group2.id}"
  end
end
