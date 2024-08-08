require 'spec_helper'

describe Cms::Node::Importer, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { nil }

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/cms/node/import/article.csv" }
  let!(:csv_file) { Fs::UploadedFile.create_from_file(csv_path) }
  let!(:ss_file) { create(:ss_file, site: site, user: user, in_file: csv_file) }

  def find_node(filename)
    Cms::Node.site(site).where(filename: filename).first
  end

  context "article nodes" do
    it "#import" do
      importer = described_class.new(site, node, user)
      importer.import(ss_file)

      # TODO and Memo:
      # do import and find node and check nodes attributes ...
    end
  end
end
