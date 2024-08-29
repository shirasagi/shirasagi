require 'spec_helper'

describe Cms::NodeImporter, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { nil }

  let!(:group1) { create :ss_group, name: "シラサギ市", order: 10 }
  let!(:group2) { create :ss_group, name: "シラサギ市/企画政策部", order: 20 }
  let!(:group3) { create :ss_group, name: "シラサギ市/企画政策部/政策課", order: 30 }
  let!(:group4) { create :ss_group, name: "シラサギ市/企画政策部/広報課", order: 40 }
  let!(:group5) { create :ss_group, name: "シラサギ市/危機管理部", order: 50 }
  let!(:group6) { create :ss_group, name: "シラサギ市/危機管理部/管理課", order: 60 }
  let!(:group7) { create :ss_group, name: "シラサギ市/危機管理部/防災課", order: 70 }

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/cms/node/import/urgency.csv" }
  let!(:csv_file) { Fs::UploadedFile.create_from_file(csv_path) }
  let!(:ss_file) { create(:ss_file, site: site, user: user, in_file: csv_file) }

  before do
    site.group_ids += [group1.id]
    site.update!
  end

  context "urgency nodes" do
    it "#import" do
      # Check initial node count
      expect(Cms::Node.count).to eq 0

      importer = described_class.new(site, node, user)
      importer.import(ss_file)

      # Check the node count after import
      csv = CSV.read(csv_path, headers: true)
      expect(Cms::Node.count).to eq 0 #no valid node in csv
    end
  end
end
