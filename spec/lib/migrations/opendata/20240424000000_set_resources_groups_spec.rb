require 'spec_helper'
require Rails.root.join("lib/migrations/opendata/20240424000000_set_resources_groups.rb")

RSpec.describe SS::Migration20240424000000, dbscope: :example do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let!(:role) do
    role = create :cms_role_admin
    permissions = role.permissions.reject do |name|
      name.end_with?('_opendata_resources')
    end
    role.set(permissions: permissions)
  end
  let!(:targets) do
    %w(
      read_other_opendata_resources read_private_opendata_resources read_member_opendata_resources
      edit_other_opendata_resources edit_private_opendata_resources edit_member_opendata_resources
      delete_other_opendata_resources delete_private_opendata_resources delete_member_opendata_resources
      release_other_opendata_resources release_private_opendata_resources release_member_opendata_resources
      close_other_opendata_resources close_private_opendata_resources close_member_opendata_resources
    ).compact
  end
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, filename: "dataset/search" }
  let(:node) { create_once :opendata_node_dataset }
  let(:dataset) { create(:opendata_dataset, cur_node: node, group_ids: [group.id]) }
  let(:license) { create(:opendata_license, cur_site: site) }
  let(:csv_file) { Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv") }
  let(:resource) { dataset.resources.new(attributes_for(:opendata_resource, license_id: license.id)) }

  before do
    Fs::UploadedFile.create_from_file(csv_file, basename: "spec") do |f|
      resource.in_file = f
      resource.save!
    end

    described_class.new.change
  end

  it do
    role.reload
    targets.each do |target|
      expect(role.permissions.include?(target)).to be_truthy
    end

    resource.reload
    expect(resource.group_ids.include?(group.id)).to be_truthy
  end
end
