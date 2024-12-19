require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy page_search" do
    let(:site) { cms_site }
    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }
    let!(:layout) { create :cms_layout, cur_site: site }
    let!(:cate) { create :category_node_page, cur_site: site }
    let!(:page_search) do
      create(
        :cms_page_search_full, search_category_ids: [ cate.id ], search_node_ids: [ cate.id ],
        search_layout_ids: [ layout.id ], search_group_ids: [ cms_group.id ], search_user_ids: [ cms_user.id ])
    end

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = ""
      task.save!
    end

    describe "without options" do
      before do
        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::PageSearch.site(dest_site).count).to eq 0
      end
    end

    describe "with options" do
      before do
        task.copy_contents = "page_searches"
        task.save!

        perform_enqueued_jobs do
          ss_perform_now Sys::SiteCopyJob
        end
      end

      it do
        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(Cms::PageSearch.site(dest_site).count).to eq 1
        dest_layout = Cms::Layout.site(dest_site).where(filename: layout.filename).first
        dest_cate = Category::Node::Base.site(dest_site).where(filename: cate.filename).first
        dest_page_search = Cms::PageSearch.site(dest_site).first
        expect(dest_page_search.name).to eq page_search.name
        expect(dest_page_search.order).to eq page_search.order
        expect(dest_page_search.search_name).to eq page_search.search_name
        expect(dest_page_search.search_filename).to eq page_search.search_filename
        expect(dest_page_search.search_keyword).to eq page_search.search_keyword
        expect(dest_page_search.search_category_ids).to eq [ dest_cate.id ]
        expect(dest_page_search.search_group_ids).to eq page_search.search_group_ids
        expect(dest_page_search.search_layout_ids).to eq [ dest_layout.id ]
        expect(dest_page_search.search_user_ids).to eq page_search.search_user_ids
        expect(dest_page_search.search_node_ids).to eq [ dest_cate.id ]
        expect(dest_page_search.search_routes).to eq page_search.search_routes
        expect(dest_page_search.search_released_condition).to eq page_search.search_released_condition
        expect(dest_page_search.search_released_start.to_s).to eq page_search.search_released_start.to_s
        expect(dest_page_search.search_released_close.to_s).to eq page_search.search_released_close.to_s
        expect(dest_page_search.search_released_after.to_s).to eq page_search.search_released_after.to_s
        expect(dest_page_search.search_updated_condition).to eq page_search.search_updated_condition
        expect(dest_page_search.search_updated_start.to_s).to eq page_search.search_updated_start.to_s
        expect(dest_page_search.search_updated_close.to_s).to eq page_search.search_updated_close.to_s
        expect(dest_page_search.search_updated_after.to_s).to eq page_search.search_updated_after.to_s
        expect(dest_page_search.search_state).to eq page_search.search_state
        expect(dest_page_search.search_first_released).to be_nil
        expect(dest_page_search.search_approver_state).to eq page_search.search_approver_state
        expect(dest_page_search.search_sort).to eq page_search.search_sort
      end
    end
  end
end
