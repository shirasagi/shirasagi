require 'spec_helper'

describe Uploader::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :uploader_node_base }
  it_behaves_like "cms_node#spec"
end

describe Uploader::Node::File, type: :model, dbscope: :example do
  context 'cms node' do
    let(:item) { create :uploader_node_file }
    it_behaves_like "cms_node#spec"
  end

  context 'all files and directories are gone when state is changed to closed' do
    let(:item) { create(:uploader_node_file, state: 'public') }
    let(:uploader_file) { "#{item.path}/logo.png" }
    let(:sub_dirname) { "#{item.path}/#{unique_id}" }
    let(:uploader_subdir_file) { "#{sub_dirname}/keyvisual.gif" }

    before do
      ::FileUtils.mkdir_p(item.path) if !Dir.exist?(item.path)
      ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", uploader_file)
      ::FileUtils.mkdir(sub_dirname)
      ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif", uploader_subdir_file)
    end

    it do
      item.state = 'closed'
      expect { item.save! }.to raise_error Mongoid::Errors::Validations

      expect(::File.exist?(uploader_file)).to be_truthy
      expect(::File.exist?(uploader_subdir_file)).to be_truthy
    end
  end

  context 'all files and directories are gone when parent was closed' do
    let(:parent) { create(:cms_node_node, state: 'public') }
    let(:item) { create(:uploader_node_file, cur_node: parent, state: 'public') }
    let(:uploader_file) { "#{item.path}/logo.png" }
    let(:sub_dirname) { "#{item.path}/#{unique_id}" }
    let(:uploader_subdir_file) { "#{sub_dirname}/keyvisual.gif" }

    before do
      ::FileUtils.mkdir_p(item.path) if !Dir.exist?(item.path)
      ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", uploader_file)
      ::FileUtils.mkdir(sub_dirname)
      ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif", uploader_subdir_file)
    end

    it do
      parent.state = 'closed'
      parent.save!

      expect(::File.exist?(uploader_file)).to be_truthy
      expect(::File.exist?(uploader_subdir_file)).to be_truthy
    end
  end

  context 'creating routed folders under uploader' do
    let(:uploader) { create(:uploader_node_file, state: 'public') }

    context 'creating cms/node/node, this causes some errors' do
      let(:expected_error) { I18n.t('mongoid.errors.models.cms/model/node.routed_folders_under_uploader') }

      it do
        folder = build(:cms_node_node, cur_node: uploader)
        expect(folder.valid?).to be_falsey
        expect(folder.errors[:base]).to include(expected_error)
      end
    end

    context 'creating uploader/node/file, this is ok' do
      it do
        folder = build(:uploader_node_file, cur_node: uploader)
        expect(folder.valid?).to be_truthy
      end
    end
  end
end
