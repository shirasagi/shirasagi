require 'spec_helper'

describe Cms::Node::Importer, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { nil }

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/cms/node/import/category.csv" }
  let!(:csv_file) { Fs::UploadedFile.create_from_file(csv_path) }
  let!(:ss_file) { create(:ss_file, site: site, user: user, in_file: csv_file) }

  def find_node(filename)
    Cms::Node.site(site).where(filename: filename).first
  end

  context "category nodes" do
    it "#import" do
      importer = described_class.new(site, node, user)
      importer.import(ss_file)

      #TODO and Memo:
      # importing category nodes are typical use cases
      #
      # better to complete this spec firstly
      # do import and find node and check nodes attributes ...
      #
      # if node save failed; please check validation errors
      # but in some cases, the CSV format needs to be changed
      # (cases where the specifications are something wrong)
      # in the latter case, please report it

      node = find_node("anzen")
      expect(node).to be_present

      node = find_node("bosai")
      expect(node).to be_present

      node = find_node("koseki")
      expect(node).to be_present

      node = find_node("nenkin")
      expect(node).to be_present

      node = find_node("attention")
      expect(node).to be_present

      node = find_node("faq")
      expect(node).to be_present
    end
  end
end
