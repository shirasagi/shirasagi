require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout }
  let!(:article_node) { create :article_node_page, cur_site: site, layout: layout }
  let!(:photo_album_node) do
    create(
      :cms_node_photo_album, cur_site: site, cur_node: article_node, layout: layout,
      conditions: article_node.filename)
  end
  let(:attachment_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:page1) do
    file = tmp_ss_file(site: site, user: user, contents: attachment_path, basename: 'logo.png')
    create(:article_page, cur_site: site, cur_node: article_node, layout: layout, file_ids: [ file.id ], state: 'public')
  end
  let!(:page2) do
    file = tmp_ss_file(site: site, user: user, contents: attachment_path, basename: 'logo.png')
    create(:article_page, cur_site: site, cur_node: article_node, layout: layout, file_ids: [ file.id ], state: 'public')
  end

  before do
    Cms::Task.create!(site_id: site.id, node_id: nil, name: 'cms:generate_nodes', state: 'ready')
  end

  describe "#perform" do
    before do
      described_class.bind(site_id: site.id).perform_now
    end

    it do
      expect(File.exist?("#{photo_album_node.path}/index.html")).to be_truthy

      expect(Cms::Task.count).to eq 1
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_nodes').first.tap do |task|
        expect(task.state).to eq 'completed'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 0
        expect(task.logs).to include(include("#{photo_album_node.url}index.html"))
        expect(task.node_id).to be_nil
        # logs are saved in a file
        expect(::File.exist?(task.log_file_path)).to be_truthy
        # and there are no `logs` field
        expect(task[:logs]).to be_nil
        # performance logs are saved
        expect(::File.exist?(task.perf_log_file_path)).to be_truthy
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end
end
