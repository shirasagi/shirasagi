require 'spec_helper'

describe Sys::SiteImportJob, dbscope: :example do
  let!(:source_site) { create :cms_site_unique }
  let!(:layout) { create :cms_layout, cur_site: source_site }
  let!(:cate) { create :category_node_page, cur_site: source_site }
  let!(:page_search) do
    create(
      :cms_page_search_full, site: source_site, search_category_ids: [ cate.id ], search_node_ids: [ cate.id ],
      search_layout_ids: [ layout.id ], search_group_ids: [ cms_group.id ], search_user_ids: [ cms_user.id ])
  end
  let!(:file_path) do
    save_export_root = Sys::SiteExportJob.export_root
    Sys::SiteExportJob.export_root = tmpdir

    begin
      job = Sys::SiteExportJob.new
      job.task = Tasks::Cms.mock_task(source_site_id: source_site.id)
      job.perform
      output_zip = job.instance_variable_get(:@output_zip)

      output_zip
    ensure
      Sys::SiteExportJob.export_root = save_export_root
    end
  end

  describe "#perform" do
    let!(:destination_site) { create :cms_site_unique }

    it do
      job = Sys::SiteImportJob.new
      job.task = Tasks::Cms.mock_task(target_site_id: destination_site.id, import_file: file_path)
      job.perform

      expect(Cms::PageSearch.site(destination_site).count).to eq 1
      dest_layout = Cms::Layout.site(destination_site).where(filename: layout.filename).first
      dest_cate = Category::Node::Base.site(destination_site).where(filename: cate.filename).first
      dest_page_search = Cms::PageSearch.site(destination_site).first
      expect(dest_page_search.name).to eq page_search.name
      expect(dest_page_search.order).to eq page_search.order
      expect(dest_page_search.search_name).to eq page_search.search_name
      expect(dest_page_search.search_filename).to eq page_search.search_filename
      expect(dest_page_search.search_keyword).to eq page_search.search_keyword
      expect(dest_page_search.search_layout_ids).to eq [ dest_layout.id ]
      expect(dest_page_search.search_category_ids).to eq [ dest_cate.id ]
      expect(dest_page_search.search_group_ids).to eq page_search.search_group_ids
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
      expect(dest_page_search.search_first_released).to eq page_search.search_first_released
      expect(dest_page_search.search_approver_state).to eq page_search.search_approver_state
      expect(dest_page_search.search_sort).to eq page_search.search_sort
    end
  end
end
