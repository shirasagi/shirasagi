require 'spec_helper'

describe Cms::Page::GenerateJob, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  let!(:node) { create :article_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:page1) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page2) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page3) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page4) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page5) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page6) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page7) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page8) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page9) { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }

  let(:segments) { %w(web01 web02 web03) }

  let(:web01_expected_pages) { Cms::Page.all.select { |item| (item.id % segments.size) == 0 } }
  let(:web02_expected_pages) { Cms::Page.all.select { |item| (item.id % segments.size) == 1 } }
  let(:web03_expected_pages) { Cms::Page.all.select { |item| (item.id % segments.size) == 2 } }

  let(:web01_expected_path) { web01_expected_pages.map(&:path) }
  let(:web02_expected_path) { web02_expected_pages.map(&:path) }
  let(:web03_expected_path) { web03_expected_pages.map(&:path) }

  before do
    @save_generate_segments = SS.config.cms.generate_segments
    SS.config.replace_value_at(:cms, :generate_segments, { "page" => { site.host => segments } })
  end

  after do
    SS.config.replace_value_at(:cms, :generate_segments, @save_generate_segments)
  end

  describe "#perform without segment" do
    # このケースの場合、エラーになるのが望ましいんだと思う（が、そうはなっていない）
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
        expect(task.name).to eq "cms:generate_pages"
        expect(task.segment).to be_blank
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 9
        expect(task.current_count).to eq 9
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
        expect(task.name).to eq "cms:generate_pages"
        expect(task.segment).to eq "web01"
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 9
        expect(task.current_count).to eq 3
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
        expect(task.name).to eq "cms:generate_pages"
        expect(task.segment).to eq "web02"
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 9
        expect(task.current_count).to eq 3
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
        expect(task.name).to eq "cms:generate_pages"
        expect(task.segment).to eq "web03"
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 9
        expect(task.current_count).to eq 3
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
        expect(task.name).to eq "cms:generate_pages"
        expect(task.segment).to be_blank
        expect(task.state).to eq "completed"
        expect(task.started.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.closed.in_time_zone).to be_within(30.seconds).of(now)
        expect(task.total_count).to eq 9
        expect(task.current_count).to eq 9
      end
    end
  end
end
