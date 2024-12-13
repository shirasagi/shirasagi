require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy page" do
    let(:site) { cms_site }
    let(:layout) { create :cms_layout, cur_site: site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    let(:article_node) { create :article_node_page, cur_site: site, layout: layout }
    let!(:summary_page) { create :article_page, cur_site: site, cur_node: article_node, layout: layout }
    let!(:category_node) { create :category_node_page, cur_site: site, layout: layout, summary_page: summary_page }

    context "without any options" do
      before do
        task.target_host_name = target_host_name
        task.target_host_host = target_host_host
        task.target_host_domains = [ target_host_domain ]
        task.source_site_id = site.id
        task.copy_contents = ''
        task.save!
      end

      it do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end

        dest_site = Cms::Site.find_by(host: target_host_host)
        dest_category_node = Cms::Node.site(dest_site).find_by(filename: category_node.filename)
        expect(dest_category_node.summary_page_id).to be_blank
      end
    end

    context "with option 'pages'" do
      before do
        task.target_host_name = target_host_name
        task.target_host_host = target_host_host
        task.target_host_domains = [ target_host_domain ]
        task.source_site_id = site.id
        task.copy_contents = 'pages'
        task.save!
      end

      it do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end

        dest_site = Cms::Site.find_by(host: target_host_host)
        dest_summary_page = Cms::Page.site(dest_site).find_by(filename: summary_page.filename)
        expect(dest_summary_page).to be_present

        dest_category_node = Cms::Node.site(dest_site).find_by(filename: category_node.filename)
        expect(dest_category_node.summary_page_id).to eq dest_summary_page.id
      end
    end
  end
end
