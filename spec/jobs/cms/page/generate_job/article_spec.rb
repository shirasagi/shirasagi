require 'spec_helper'

describe Cms::Page::GenerateJob, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_page, cur_site: cms_site, layout_id: layout.id }
  let(:ss_file) { create :ss_file, site: site }
  let!(:page)  { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id, file_ids: [ss_file.id] }

  before do
    Cms::Task.create!(site_id: site.id, node_id: nil, name: 'cms:generate_pages', state: 'ready')
    Cms::Task.create!(site_id: site.id, node_id: node.id, name: 'cms:generate_pages', state: 'ready')
  end

  describe "#perform without node" do
    before do
      Fs.rm_rf page.path
      page.files.each { |file| Fs.rm_rf file.public_path }

      described_class.bind(site_id: site).perform_now
    end

    it do
      expect(File.exist?(page.path)).to be_truthy
      page.files.each do |file|
        expect(File.exist?(file.public_path)).to be_truthy
      end

      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'stop'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 1
        expect(task.current_count).to eq 1
        expect(task.logs).to include(include(page.filename))
        expect(task.node_id).to be_nil
        # logs are saved in a file
        expect(::File.exists?(task.log_file_path)).to be_truthy
        # and there are no `logs` field
        expect(task[:logs]).to be_nil
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'ready'
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end

  describe "#perform with node" do
    before do
      Fs.rm_rf page.path
      page.files.each { |file| Fs.rm_rf file.public_path }

      described_class.bind(site_id: site, node_id: node).perform_now
    end

    it do
      expect(File.exist?(page.path)).to be_truthy
      page.files.each do |file|
        expect(File.exist?(file.public_path)).to be_truthy
      end

      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'ready'
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'stop'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 1
        expect(task.current_count).to eq 1
        expect(task.logs).to include(include(page.filename))
        expect(task.node_id).to eq node.id
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end
end
