require 'spec_helper'

describe Cms::Role::ImportJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:site2) { create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp" }

  let!(:role1) { create :cms_role, name: "role1", permissions: [], cur_site: site }
  let!(:role2) { create :cms_role, name: "role2", permissions: [], cur_site: site }
  let!(:role3) { create :cms_role, name: "role3", permissions: [], cur_site: site2 }

  let(:path) { "#{Rails.root}/spec/fixtures/cms/role/cms_roles_2.csv" }
  let(:ss_file) do
    SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
      ::FileUtils.cp(path, file.path)
    end
  end

  before do
    described_class.bind(site_id: site).perform_now(ss_file.id)
  end

  it ".perform_now" do
    expect(Job::Log.count).to eq 1
    Job::Log.first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)

      expect(Cms::Role.find(role1.id).permissions.present?).to be_truthy
      expect(Cms::Role.find(role2.id).permissions.present?).to be_truthy
      expect(Cms::Role.find(role3.id).permissions.present?).to be_falsey
    end
  end
end
