require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  let!(:root_page1) { create :cms_page, cur_site: cms_site, filename: "index.html", layout_id: layout.id }
  let!(:root_page2) { create :cms_page, cur_site: cms_site, filename: "page2.html", layout_id: layout.id }
  let!(:root_page3) { create :cms_page, cur_site: cms_site, filename: "page3.html", layout_id: layout.id }

  let!(:node1) { create :article_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:node1_page1) { create :article_page, cur_site: cms_site, cur_node: node1, layout_id: layout.id }
  let!(:node1_page2) { create :article_page, cur_site: cms_site, cur_node: node1, layout_id: layout.id }

  let!(:node2) { create :event_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:node1_page1) { create :event_page, cur_site: cms_site, cur_node: node2, layout_id: layout.id }
  let!(:node1_page2) { create :event_page, cur_site: cms_site, cur_node: node2, layout_id: layout.id }

  let!(:node3) { create :faq_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:node3_page1) { create :faq_page, cur_site: cms_site, cur_node: node3, layout_id: layout.id }
  let!(:node3_page2) { create :faq_page, cur_site: cms_site, cur_node: node3, layout_id: layout.id }

  let!(:node4) { create :article_node_page, cur_site: cms_site, cur_node: node1, layout_id: layout.id }
  let!(:node4_page1) { create :article_page, cur_site: cms_site, cur_node: node4, layout_id: layout.id }
  let!(:node4_page2) { create :article_page, cur_site: cms_site, cur_node: node4, layout_id: layout.id }

  let!(:node5) { create :event_node_page, cur_site: cms_site, cur_node: node2, layout_id: layout.id }
  let!(:node5_page1) { create :event_page, cur_site: cms_site, cur_node: node5, layout_id: layout.id }
  let!(:node5_page2) { create :event_page, cur_site: cms_site, cur_node: node5, layout_id: layout.id }

  let!(:node6) { create :faq_node_page, cur_site: cms_site, cur_node: node3, layout_id: layout.id }
  let!(:node6_page1) { create :faq_page, cur_site: cms_site, cur_node: node6, layout_id: layout.id }
  let!(:node6_page2) { create :faq_page, cur_site: cms_site, cur_node: node6, layout_id: layout.id }

  let(:segments) { %w(web01 web02 web03) }

  let(:web01_expected_pages) { Cms::Page.where(depth: 1).select { |item| (item.id % segments.size) == 0 } }
  let(:web02_expected_pages) { Cms::Page.where(depth: 1).select { |item| (item.id % segments.size) == 1 } }
  let(:web03_expected_pages) { Cms::Page.where(depth: 1).select { |item| (item.id % segments.size) == 2 } }

  let(:web01_expected_nodes) { Cms::Node.all.select { |item| (item.id % segments.size) == 0 } }
  let(:web02_expected_nodes) { Cms::Node.all.select { |item| (item.id % segments.size) == 1 } }
  let(:web03_expected_nodes) { Cms::Node.all.select { |item| (item.id % segments.size) == 2 } }

  let(:web01_expected_path) do
    web01_expected_pages.map(&:path) + web01_expected_nodes.map { |item| ::File.join(item.path, "index.html") }
  end
  let(:web02_expected_path) do
    web02_expected_pages.map(&:path) + web02_expected_nodes.map { |item| ::File.join(item.path, "index.html") }
  end
  let(:web03_expected_path) do
    web03_expected_pages.map(&:path) + web03_expected_nodes.map { |item| ::File.join(item.path, "index.html") }
  end

  before do
    @save_generate_segments = SS.config.cms.generate_segments
    SS.config.replace_value_at(:cms, :generate_segments, { "node" => { site.host => segments } })
  end

  after do
    SS.config.replace_value_at(:cms, :generate_segments, @save_generate_segments)
  end

  describe "#perform without segment" do
    before do
      Fs.rm_rf site.path
      expect { described_class.bind(site_id: site.id).perform_now }.to output.to_stdout
    end

    it do
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }

      expect(SS::Task.all.count).to eq 1
      SS::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.name).to eq "cms:generate_nodes"
        expect(task.segment).to be_blank
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 3
      end
    end
  end

  describe "#perform with web01" do
    before do
      Fs.rm_rf site.path
      expect { described_class.bind(site_id: site.id).perform_now(segment: "web01") }.to output.to_stdout
    end

    it do
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }

      expect(SS::Task.all.count).to eq 1
      SS::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.name).to eq "cms:generate_nodes"
        expect(task.segment).to eq "web01"
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 1
      end
    end
  end

  describe "#perform with web02" do
    before do
      Fs.rm_rf site.path
      expect { described_class.bind(site_id: site.id).perform_now(segment: "web02") }.to output.to_stdout
    end

    it do
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }

      expect(SS::Task.all.count).to eq 1
      SS::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.name).to eq "cms:generate_nodes"
        expect(task.segment).to eq "web02"
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 1
      end
    end
  end

  describe "#perform with web03" do
    before do
      Fs.rm_rf site.path
      expect { described_class.bind(site_id: site.id).perform_now(segment: "web03") }.to output.to_stdout
    end

    it do
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_falsey }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }

      expect(SS::Task.all.count).to eq 1
      SS::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.name).to eq "cms:generate_nodes"
        expect(task.segment).to eq "web03"
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 1
      end
    end
  end

  describe "#perform with undefined segment" do
    # このケースの場合、（エラーになるのが望ましいかもしれないが）segment が未指定の場合と同じ動作となる
    before do
      Fs.rm_rf site.path
      expect { described_class.bind(site_id: site.id).perform_now(segment: "undef-#{unique_id}") }.to output.to_stdout
    end

    it do
      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      web01_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web02_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }
      web03_expected_path.each { |path| expect(::File.exist?(path)).to be_truthy }

      expect(SS::Task.all.count).to eq 1
      SS::Task.all.first.tap do |task|
        expect(task.site_id).to eq site.id
        expect(task.name).to eq "cms:generate_nodes"
        expect(task.segment).to be_blank # segment が nil でないと、書き出しの状況を管理画面に正しく表示できない
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 3
      end
    end
  end
end
