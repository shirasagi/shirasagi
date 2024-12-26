require 'spec_helper'

describe Cms::Node::ImportJob, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }

  let(:path) { "#{Rails.root}/spec/fixtures/cms/node/import/category.csv" }
  let(:ss_file) do
    SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
      FileUtils.cp(path, file.path)
    end
  end

  context "import in root" do
    it do
      described_class.bind(site_id: site.id).perform_now(ss_file.id)
    end
  end

  context "import in under the node" do
    it do
      described_class.bind(site_id: site.id, node_id: node.id).perform_now(ss_file.id)
    end
  end
end
