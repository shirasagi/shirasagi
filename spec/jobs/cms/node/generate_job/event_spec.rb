require 'spec_helper'

describe Cms::Node::GenerateJob, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:cate)   { create :category_node_page, cur_site: cms_site, cur_node: node, layout_id: layout.id }
  let!(:page)  do
    create(:event_page, cur_site: cms_site, cur_node: node, layout_id: layout.id)
  end

  before do
    Cms::Task.create!(site_id: site.id, node_id: node.id, name: 'cms:generate_nodes', state: 'ready')
    Cms::Task.create!(site_id: site.id, node_id: nil, name: 'cms:generate_nodes', state: 'ready')

    node.st_category_ids = [ cate.id ]
    node.save!

    page.category_ids = [ cate.id ]
    page.save!
  end

  describe "#perform" do
    context "generate all" do
      let(:node) { create :event_node_page, cur_site: cms_site, layout_id: layout.id, event_display: "list" }

      before do
        described_class.bind(site_id: site).perform_now
      end

      it do
        expect(File.exist?("#{node.path}/index.html")).to be_truthy
        expect(File.exist?("#{node.path}/index.ics")).to be_truthy
        expect(File.exist?("#{node.path}/table.html")).to be_falsey
        expect(File.exist?("#{node.path}/list.html")).to be_falsey

        this_month = Time.zone.now.beginning_of_month
        cur_month = this_month - 1.year
        while cur_month <= this_month + 1.year
          expect(File.exist?("#{node.path}/#{cur_month.strftime("%Y%m")}/index.html")).to be_truthy
          expect(File.exist?("#{node.path}/#{cur_month.strftime("%Y%m")}/list.html")).to be_truthy
          expect(File.exist?("#{node.path}/#{cur_month.strftime("%Y%m")}/table.html")).to be_truthy

          cur_month += 1.month
        end

        expect { ::Icalendar::Calendar.parse(::File.read("#{node.path}/index.ics")) }.not_to raise_error

        expect(Cms::Task.count).to eq 2
        Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_nodes').first.tap do |task|
          expect(task.state).to eq 'stop'
          expect(task.started).not_to be_nil
          expect(task.closed).not_to be_nil
          expect(task.total_count).to eq 0
          expect(task.current_count).to eq 0
          expect(task.logs).to include(include("#{node.url}index.html"))
          expect(task.logs).to include(include("#{node.url}index.ics"))
          expect(task.node_id).to be_nil
        end
        Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_nodes').first.tap do |task|
          expect(task.state).to eq 'ready'
        end

        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end
      end
    end

    context "generate node with list_only" do
      let(:node) { create :event_node_page, cur_site: cms_site, layout_id: layout.id, event_display: "list_only" }

      before do
        described_class.bind(site_id: site, node_id: node).perform_now
      end

      it do
        expect(File.exist?("#{node.path}/index.html")).to be_truthy
        expect(File.exist?("#{node.path}/index.ics")).to be_truthy
        expect(File.exist?("#{node.path}/table.html")).to be_falsey
        expect(File.exist?("#{node.path}/list.html")).to be_falsey

        this_month = Time.zone.now.beginning_of_month
        cur_month = this_month - 1.year
        while cur_month <= this_month + 1.year
          expect(File.exist?("#{node.path}/#{cur_month.strftime("%Y%m")}/index.html")).to be_truthy
          expect(File.exist?("#{node.path}/#{cur_month.strftime("%Y%m")}/list.html")).to be_truthy
          expect(File.exist?("#{node.path}/#{cur_month.strftime("%Y%m")}/table.html")).to be_falsey

          cur_month += 1.month
        end

        expect { ::Icalendar::Calendar.parse(::File.read("#{node.path}/index.ics")) }.not_to raise_error

        Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_nodes').first.tap do |task|
          expect(task.state).to eq 'stop'
        end
      end
    end
  end
end
