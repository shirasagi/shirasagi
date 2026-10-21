require 'spec_helper'

describe Opendata::Harvest::ImportJob, type: :feature, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create(:opendata_node_dataset, cur_site: site) }
  let(:file_path) { "#{Rails.root}/tmp/hacked-#{$$}" }
  let(:vulnerable_url) { "|touch #{file_path} #" }
  let!(:importer) do
    create :opendata_harvest_importer, cur_site: site, cur_node: node, source_url: unique_url, api_type: "ckan"
  end

  before do
    FileUtils.rm_f(file_path)
    importer.set(source_url: vulnerable_url)
  end

  it do
    described_class.bind(site_id: site, node_id: node).perform_now(importers: [ importer.id ])
    expect(File.exist?(file_path)).to be_falsey
  end
end
