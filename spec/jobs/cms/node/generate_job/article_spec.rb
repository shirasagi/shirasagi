require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :article_node_page, cur_site: cms_site, layout_id: layout.id }
  let!(:page)  { create :article_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }

  before do
    Cms::Task.create!(site_id: site.id, node_id: nil, name: 'cms:generate_nodes', state: 'ready')
    Cms::Task.create!(site_id: site.id, node_id: node.id, name: 'cms:generate_nodes', state: 'ready')
  end

  describe "#perform without node" do
    before do
      described_class.bind(site_id: site.id).perform_now
    end

    it do
      expect(File.exist?("#{node.path}/index.html")).to be_truthy

      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_nodes').first.tap do |task|
        expect(task.state).to eq 'completed'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 0
        expect(task.logs).to include(include("#{node.url}index.html"))
        expect(task.node_id).to be_nil
        # logs are saved in a file
        expect(File.exist?(task.log_file_path)).to be_truthy
        # and there are no `logs` field
        expect(task[:logs]).to be_nil
        # performance logs are saved
        expect(File.exist?(task.perf_log_file_path)).to be_truthy
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_nodes').first.tap do |task|
        expect(task.state).to eq 'ready'
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_nodes').first.tap do |task|
        Cms::GenerationReportCreateJob.bind(site_id: site.id).perform_now(task.id)

        expect(Job::Log.count).to eq 2
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::GenerationReport::Title.all.count).to eq 1
        title = Cms::GenerationReport::Title.all.first
        expect(title.site_id).to eq site.id
        expect(title.name).to include("generate node performance")
        expect(title.task_id).to eq task.id
        expect(title.sha256_hash).to be_present
        expect(title.generation_type).to eq "nodes"

        expect(Cms::GenerationReport::History[title].all.count).to eq 3
        Cms::GenerationReport::History[title].all.to_a.tap do |histories|
          expect(histories[0].site_id).to eq site.id
          expect(histories[0].task_id).to eq task.id
          expect(histories[0].title_id).to eq title.id
          expect(histories[0].history_type).to eq "layout"
          expect(histories[0].content_id).to eq layout.id
          expect(histories[0].content_name).to eq layout.name
          expect(histories[0].content_filename).to eq layout.filename
          expect(histories[0].db).to be > 0
          expect(histories[0].view).to be_nil
          expect(histories[0].elapsed).to be > 0
          expect(histories[0].total_db).to be > 0
          expect(histories[0].total_view).to be_nil
          expect(histories[0].total_elapsed).to be > 0
          expect(histories[0].sub_total_db).to be_nil
          expect(histories[0].sub_total_view).to be_nil
          expect(histories[0].sub_total_elapsed).to be_nil

          expect(histories[1].site_id).to eq site.id
          expect(histories[1].task_id).to eq task.id
          expect(histories[1].title_id).to eq title.id
          expect(histories[1].history_type).to eq "node"
          expect(histories[1].content_id).to eq node.id
          expect(histories[1].content_name).to eq node.name
          expect(histories[1].content_filename).to eq node.filename
          expect(histories[1].db).to be > 0
          expect(histories[1].view).to be > 0
          expect(histories[1].elapsed).to be > 0
          expect(histories[1].total_db).to be > 0
          expect(histories[1].total_view).to be > 0
          expect(histories[1].total_elapsed).to be > 0
          expect(histories[1].sub_total_db).to be > 0
          expect(histories[1].sub_total_view).to be >= 0
          expect(histories[1].sub_total_elapsed).to be > 0

          expect(histories[2].site_id).to eq site.id
          expect(histories[2].task_id).to eq task.id
          expect(histories[2].title_id).to eq title.id
          expect(histories[2].history_type).to eq "site"
          expect(histories[2].content_id).to eq site.id
          expect(histories[2].content_name).to eq site.name
          expect(histories[2].content_filename).to be_blank
          expect(histories[2].db).to be > 0
          expect(histories[2].view).to be >= 0
          expect(histories[2].elapsed).to be > 0
          expect(histories[2].total_db).to be > 0
          expect(histories[2].total_view).to be > 0
          expect(histories[2].total_elapsed).to be > 0
          expect(histories[2].sub_total_db).to be > 0
          expect(histories[2].sub_total_view).to be > 0
          expect(histories[2].sub_total_elapsed).to be > 0
        end

        expect(Cms::GenerationReport::Aggregation[title].all.count).to eq 1
        Cms::GenerationReport::Aggregation[title].all.to_a.tap do |aggregations|
          expect(aggregations[0].site_id)
          expect(aggregations[0].task_id).to eq task.id
          expect(aggregations[0].title_id).to eq title.id
          expect(aggregations[0].history_type).to eq "layout"
          expect(aggregations[0].content_id).to eq layout.id
          expect(aggregations[0].content_name).to eq layout.name
          expect(aggregations[0].content_filename).to eq layout.filename
          expect(aggregations[0].db).to be > 0
          expect(aggregations[0].view).to be >= 0
          expect(aggregations[0].elapsed).to be > 0
          expect(aggregations[0].total_db).to be > 0
          expect(aggregations[0].total_view).to be >= 0
          expect(aggregations[0].total_elapsed).to be > 0
          expect(aggregations[0].sub_total_db).to be >= 0
          expect(aggregations[0].sub_total_view).to be >= 0
          expect(aggregations[0].sub_total_elapsed).to be >= 0
        end
      end
    end
  end

  describe "#perform with node" do
    before do
      described_class.bind(site_id: site.id, node_id: node.id).perform_now
    end

    it do
      expect(File.exist?("#{node.path}/index.html")).to be_truthy

      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_nodes').first.tap do |task|
        expect(task.state).to eq 'ready'
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_nodes').first.tap do |task|
        expect(task.state).to eq 'completed'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 0
        expect(task.logs).to include(include("#{node.url}index.html"))
        expect(task.node_id).to eq node.id
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end

  describe "#perform with generate_lock" do
    before do
      @save_config = SS.config.cms.generate_lock
      SS.config.replace_value_at(:cms, 'generate_lock', { 'disable' => false, 'options' => ['1.hour'] })
      site.set(generate_lock_until: Time.zone.now + 1.hour)

      described_class.bind(site_id: site.id).perform_now
    end

    after do
      SS.config.replace_value_at(:cms, 'generate_lock', @save_config)
    end

    it do
      expect(File.exist?("#{node.path}/index.html")).to be_falsey

      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_nodes').first.tap do |task|
        expect(task.state).to eq 'completed'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 0
        expect(task.logs).not_to include(include("#{node.url}index.html"))
        expect(task.node_id).to be_nil
        # logs are saved in a file
        expect(File.exist?(task.log_file_path)).to be_truthy
        # and there are no `logs` field
        expect(task[:logs]).to be_nil
        # performance logs are saved
        expect(File.exist?(task.perf_log_file_path)).to be_truthy
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_nodes').first.tap do |task|
        expect(task.state).to eq 'ready'
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include(I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_locked')))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end
end
