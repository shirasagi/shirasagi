require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy node" do
    let(:site) { cms_site }
    let(:layout) { create :cms_layout, cur_site: site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = ''
      task.save!
    end

    describe "copy cms/node" do
      let(:upper_html) { '<div><span>upper</span>' }
      let(:loop_html) { '<article class="#{class}"><header><h2>#{name}</h2></header><p>#{summary}</p></article>' }
      let(:lower_html) { '<span>lower</span></div>' }
      let!(:node1) do
        create(:cms_node_node, cur_site: site, layout_id: layout.id,
               upper_html: upper_html, loop_html: loop_html, lower_html: lower_html)
      end
      let!(:node2) do
        create(:article_node_page, cur_site: site, layout_id: layout.id,
               upper_html: upper_html, loop_html: loop_html, lower_html: lower_html,
               opendata_site_ids: [ 5 ])
      end
      let!(:node3) do
        create(:facility_node_node, cur_site: site, layout_id: layout.id,
               upper_html: upper_html, loop_html: loop_html, lower_html: lower_html,
               opendata_site_ids: [ 5 ], csv_assoc: 'enabled')
      end

      before do
        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.log).not_to include('WARN')
          expect(log.log).not_to include('ERROR')
          expect(log.log).to include('INFO -- : Completed Job')
        end

        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        dest_layout = Cms::Layout.site(dest_site).find_by(filename: layout.filename)
        expect(dest_layout.name).to eq layout.name
        expect(dest_layout.user_id).to eq layout.user_id
        expect(dest_layout.html).to eq layout.html

        Cms::Node.site(dest_site).find_by(filename: node1.filename).tap do |dest_node|
          dest_node = dest_node.becomes_with_route
          expect(dest_node.name).to eq node1.name
          expect(dest_node.layout_id).to eq dest_layout.id
          expect(dest_node.user_id).to eq node1.user_id
          expect(dest_node.upper_html).to eq node1.upper_html
          expect(dest_node.loop_html).to eq node1.loop_html
          expect(dest_node.lower_html).to eq node1.lower_html
        end

        Cms::Node.site(dest_site).find_by(filename: node2.filename).tap do |dest_node|
          dest_node = dest_node.becomes_with_route
          expect(dest_node.name).to eq node2.name
          expect(dest_node.layout_id).to eq dest_layout.id
          expect(dest_node.user_id).to eq node2.user_id
          expect(dest_node.upper_html).to eq node2.upper_html
          expect(dest_node.loop_html).to eq node2.loop_html
          expect(dest_node.lower_html).to eq node2.lower_html
          expect(dest_node.opendata_site_ids).to eq []
        end

        Cms::Node.site(dest_site).find_by(filename: node3.filename).tap do |dest_node|
          dest_node = dest_node.becomes_with_route
          expect(dest_node.name).to eq node3.name
          expect(dest_node.layout_id).to eq dest_layout.id
          expect(dest_node.user_id).to eq node2.user_id
          expect(dest_node.upper_html).to eq node2.upper_html
          expect(dest_node.loop_html).to eq node2.loop_html
          expect(dest_node.lower_html).to eq node2.lower_html
          expect(dest_node.opendata_site_ids).to eq []
          expect(dest_node.csv_assoc).to be_nil
        end
      end
    end

    describe "copy article/page node which contains curcular reference" do
      let!(:node1) { create :article_node_page, cur_site: site, layout_id: layout.id }
      let!(:node2) { create :article_node_page, cur_site: site, layout_id: layout.id }

      before do
        # node1 refers to node2
        node1.st_category_ids = [ node2.id ]
        node1.save!

        # node2 refers to node1
        node2.st_category_ids = [ node1.id ]
        node2.save!

        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.log).not_to include('WARN')
          expect(log.log).not_to include('ERROR')
          expect(log.log).to include('INFO -- : Completed Job')
        end

        dest_site = Cms::Site.find_by(host: target_host_host)

        dest_node1 = Cms::Node.site(dest_site).find_by(filename: node1.filename)
        dest_node1 = dest_node1.becomes_with_route

        dest_node2 = Cms::Node.site(dest_site).find_by(filename: node2.filename)
        dest_node2 = dest_node2.becomes_with_route

        expect(dest_node1.st_category_ids).to eq [dest_node2.id]
        expect(dest_node2.st_category_ids).to eq [dest_node1.id]
      end
    end
  end
end
