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
      let!(:node) { create :cms_node_node, cur_site: site, layout_id: layout.id }

      before do
        node.upper_html = '<div><span>upper</span>'
        node.loop_html = '<article class="#{class}"><header><h2>#{name}</h2></header><p>#{summary}</p></article>'
        node.lower_html = '<span>lower</span></div>'
        node.save!

        perform_enqueued_jobs do
          Sys::SiteCopyJob.perform_now
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        dest_layout = Cms::Layout.site(dest_site).find_by(filename: layout.filename)
        expect(dest_layout.name).to eq layout.name
        expect(dest_layout.user_id).to eq layout.user_id
        expect(dest_layout.html).to eq layout.html

        dest_node = Cms::Node.site(dest_site).find_by(filename: node.filename)
        dest_node = dest_node.becomes_with_route
        expect(dest_node.name).to eq node.name
        expect(dest_node.layout_id).to eq dest_layout.id
        expect(dest_node.user_id).to eq node.user_id
        expect(dest_node.upper_html).to eq node.upper_html
        expect(dest_node.loop_html).to eq node.loop_html
        expect(dest_node.lower_html).to eq node.lower_html

        expect(Job::Log.count).to eq 1
        log = Job::Log.first
        expect(log.logs).not_to include(include('WARN'))
        expect(log.logs).not_to include(include('ERROR'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
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
