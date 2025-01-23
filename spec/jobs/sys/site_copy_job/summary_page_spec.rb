require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy page" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }
    let!(:group) do
      group = Cms::Group.find(user.groups.first.id)
      group.contact_groups.create(
        name: "name-#{unique_id}", contact_group_name: "group_name-#{unique_id}",
        contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
        contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
        main_state: "main")

      Cms::Group.find(user.groups.first.id)
    end
    let!(:layout) { create :cms_layout, cur_site: site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    let(:article_node) { create :article_node_page, cur_site: site, cur_user: user, layout: layout }
    let!(:summary_page) do
      create(
        :article_page, cur_site: site, cur_user: user, cur_node: article_node, layout: layout,
        contact_state: 'show', contact_group_id: group.id, contact_group_relation: 'related',
        contact_group_contact_id: group.contact_groups.first.id
      )
    end
    let!(:category_node) { create :category_node_page, cur_site: site, layout: layout, summary_page: summary_page }

    context "without any options" do
      before do
        task.target_host_name = target_host_name
        task.target_host_host = target_host_host
        task.target_host_domains = [ target_host_domain ]
        task.source_site_id = site.id
        task.copy_contents = ''
        task.save!
        Rails.logger.debug("♦︎♦︎ without any options コピー元 summary_page ID: #{summary_page.id}")
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
        Rails.logger.debug("♦︎♦︎ with option 'pages' コピー元 summary_page ID: #{summary_page.id}")
      end

      it do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end

        dest_site = Cms::Site.find_by(host: target_host_host)
        dest_summary_page = Cms::Page.site(dest_site).find_by(filename: summary_page.filename)
        expect(dest_summary_page).to be_present

        dest_category_node = Cms::Node.site(dest_site).find_by(filename: category_node.filename)
        expect(dest_category_node.summary_page_id).to eq summary_page.id
      end
    end
  end
end
