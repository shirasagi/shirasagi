require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy opendata site" do
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
      task.copy_contents = 'pages'
      task.save!
    end

    describe "copy opendata/dataset" do
      let(:node) { create :opendata_node_dataset, cur_site: site, layout_id: layout.id }
      let(:node_category) { create :opendata_node_category, cur_site: site, layout_id: layout.id }
      let(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id }
      let(:dataset_group) { create :opendata_dataset_group, cur_site: site, category_ids: [ node_category.id ] }
      let!(:node_dataset_search) { create :opendata_node_search_dataset, cur_site: site, layout_id: layout.id }
      let!(:page) do
        create :opendata_dataset, cur_site: site, cur_node: node, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ], dataset_group_ids: [ dataset_group.id ]
      end

      before do
        license_logo = Rails.root.join("spec", "fixtures", "ss", "logo.png")
        license = Fs::UploadedFile.create_from_file(license_logo, basename: "spec") do |file|
          create(:opendata_license, cur_site: site, in_file: file)
        end

        file_path = Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv")
        Fs::UploadedFile.create_from_file(file_path, basename: "spec") do |file|
          resource = page.resources.new(attributes_for(:opendata_resource))
          resource.in_file = file
          resource.license_id = license.id
          resource.save!
          page.save!
        end

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

        expect(page.resources.count).to eq 1
        resource = page.resources.first
        Cms::Page.site(dest_site).find_by(filename: page.filename).tap do |dest_page|
          dest_page = dest_page.becomes_with_route
          expect(dest_page.name).to eq page.name
          expect(dest_page.layout_id).to eq dest_layout.id
          expect(dest_page.user_id).to eq page.user_id
          expect(dest_page.text).to eq page.text
          expect(dest_page.category_ids).not_to eq page.category_ids
          expect(dest_page.categories.pluck(:name)).to eq page.categories.pluck(:name)
          expect(dest_page.area_ids).not_to eq page.area_ids
          expect(dest_page.areas.pluck(:name)).to eq page.areas.pluck(:name)
          expect(dest_page.dataset_group_ids).not_to eq page.dataset_group_ids
          expect(dest_page.dataset_groups.pluck(:name)).to eq page.dataset_groups.pluck(:name)
          expect(dest_page.resources.count).to eq 1
          dest_page.resources.first.tap do |dest_resource|
            expect(dest_resource.name).to eq resource.name
            expect(dest_resource.text).to eq resource.text
            expect(dest_resource.filename).to eq resource.filename
            expect(dest_resource.format).to eq resource.format
            expect(dest_resource.rdf_iri).to eq resource.rdf_iri
            expect(dest_resource.rdf_error).to eq resource.rdf_error
            expect(dest_resource.license_id).not_to eq resource.license_id
            expect(dest_resource.license.name).to eq resource.license.name
            expect(dest_resource.file_id).not_to eq resource.file_id
            expect(dest_resource.file.name).to eq resource.file.name
            expect(dest_resource.file.size).to eq resource.file.size
            expect(dest_resource.file.content_type).to eq resource.file.content_type
          end
        end
      end
    end

    describe "copy opendata/app" do
      let(:node) { create :opendata_node_app, cur_site: site, layout_id: layout.id }
      let(:node_category) { create :opendata_node_category, cur_site: site, layout_id: layout.id }
      let(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id }

      let(:dataset_group) { create :opendata_dataset_group, cur_site: site, category_ids: [ node_category.id ] }
      let!(:node_dataset_search) { create :opendata_node_search_dataset, cur_site: site, layout_id: layout.id }
      let(:dataset) do
        create :opendata_dataset, cur_site: site, cur_node: node, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ], dataset_group_ids: [ dataset_group.id ]
      end

      let!(:node_app_search) { create :opendata_node_search_app, cur_site: site, layout_id: layout.id }
      let!(:app1) do
        create :opendata_app, cur_site: site, cur_node: node, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ]
      end
      let!(:app2) do
        create :opendata_app, cur_site: site, cur_node: node, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ]
      end

      before do
        file_path = Rails.root.join("spec", "fixtures", "opendata", "shift_jis.csv")
        Fs::UploadedFile.create_from_file(file_path, basename: "spec") do |file|
          appfile = app1.appfiles.new(text: "aaa", format: "csv")
          appfile.in_file = file
          appfile.save!
        end

        app1.dataset_ids = [ dataset.id ]
        app1.save!

        app2.appurl = "http://opendata.example.jp"
        app2.dataset_ids = [ dataset.id ]
        app2.save!

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

        expect(app1.id).to be < dataset.id
        expect(app2.id).to be < dataset.id

        dest_site = Cms::Site.find_by(host: target_host_host)
        expect(dest_site.id).not_to eq site.id
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        dest_layout = Cms::Layout.site(dest_site).find_by(filename: layout.filename)
        expect(dest_layout.id).not_to eq layout.id
        expect(dest_layout.name).to eq layout.name
        expect(dest_layout.user_id).to eq layout.user_id
        expect(dest_layout.html).to eq layout.html

        dest_dataset = Cms::Page.site(dest_site).find_by(filename: dataset.filename)
        expect(dest_dataset.id).not_to eq dataset.id
        expect(dest_dataset.name).to eq dataset.name

        Cms::Page.site(dest_site).find_by(filename: app1.filename).tap do |dest_app|
          dest_app = dest_app.becomes_with_route
          expect(dest_app.name).to eq app1.name
          expect(dest_app.layout_id).to eq dest_layout.id
          expect(dest_app.user_id).to eq app1.user_id
          expect(dest_app.text).to eq app1.text
          expect(dest_app.category_ids).not_to eq app1.category_ids
          expect(dest_app.categories.pluck(:name)).to eq app1.categories.pluck(:name)
          expect(dest_app.area_ids).not_to eq app1.area_ids
          expect(dest_app.areas.pluck(:name)).to eq app1.areas.pluck(:name)
          expect(dest_app.dataset_ids).to eq [ dest_dataset.id ]
          expect(dest_app.appfiles.count).to eq 1
          appfile = app1.appfiles.first
          dest_app.appfiles.first.tap do |dest_appfile|
            expect(dest_appfile.text).to eq appfile.text
            expect(dest_appfile.filename).to eq appfile.filename
            expect(dest_appfile.format).to eq appfile.format
            expect(dest_appfile.file_id).not_to eq appfile.file_id
            expect(dest_appfile.file.name).to eq appfile.file.name
            expect(dest_appfile.file.size).to eq appfile.file.size
            expect(dest_appfile.file.content_type).to eq appfile.file.content_type
          end
        end

        Cms::Page.site(dest_site).find_by(filename: app2.filename).tap do |dest_app|
          dest_app = dest_app.becomes_with_route
          expect(dest_app.name).to eq app2.name
          expect(dest_app.layout_id).to eq dest_layout.id
          expect(dest_app.user_id).to eq app2.user_id
          expect(dest_app.text).to eq app2.text
          expect(dest_app.category_ids).not_to eq app2.category_ids
          expect(dest_app.categories.pluck(:name)).to eq app2.categories.pluck(:name)
          expect(dest_app.area_ids).not_to eq app2.area_ids
          expect(dest_app.areas.pluck(:name)).to eq app2.areas.pluck(:name)
          expect(dest_app.dataset_ids).to eq [ dest_dataset.id ]
          expect(dest_app.appfiles.count).to eq 0
          expect(dest_app.appurl).to eq app2.appurl
        end
      end
    end

    describe "copy opendata/idea" do
      let(:node_category) { create :opendata_node_category, cur_site: site, layout_id: layout.id }
      let(:node_area) { create :opendata_node_area, cur_site: site, layout_id: layout.id }

      # dataset
      let(:dataset_node) { create :opendata_node_dataset, cur_site: site, layout_id: layout.id }
      let(:dataset_group) { create :opendata_dataset_group, cur_site: site, category_ids: [ node_category.id ] }
      let!(:node_dataset_search) { create :opendata_node_search_dataset, cur_site: site, layout_id: layout.id }
      let(:dataset) do
        create :opendata_dataset, cur_site: site, cur_node: dataset_node, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ], dataset_group_ids: [ dataset_group.id ]
      end

      # app
      let(:node_app) { create :opendata_node_app, cur_site: site, layout_id: layout.id }
      let!(:node_app_search) { create :opendata_node_search_app, cur_site: site, layout_id: layout.id }
      let(:app1) do
        create :opendata_app, cur_site: site, cur_node: node_app, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ]
      end
      let(:app2) do
        create :opendata_app, cur_site: site, cur_node: node_app, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ]
      end

      # idea
      let(:node_idea) { create :opendata_node_idea, cur_site: site, layout_id: layout.id }
      let!(:node_idea_search) { create :opendata_node_search_idea, cur_site: site, layout_id: layout.id }
      let!(:idea1) do
        create :opendata_idea, cur_site: site, cur_node: node_idea, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ]
      end
      let!(:idea2) do
        create :opendata_idea, cur_site: site, cur_node: node_idea, layout_id: layout.id,
               category_ids: [ node_category.id ], area_ids: [ node_area.id ]
      end

      let!(:node_idea) { create_once :opendata_node_idea }

      let(:member) { cms_member }

      before do
        create :opendata_idea_comment, site_id: site, idea_id: idea1.id, member_id: member.id
        create :opendata_idea_comment, site_id: site, idea_id: idea1.id, member_id: member.id
        create :opendata_idea_comment, site_id: site, idea_id: idea2.id, member_id: member.id

        idea1.commented = idea1.comments.order_by(updated: -1).first.updated
        idea1.total_comment = idea1.comments.count
        idea1.dataset_ids = [ dataset.id ]
        idea1.issue = unique_id
        idea1.data = unique_id
        idea1.note = unique_id
        idea1.save!

        idea2.commented = idea2.comments.order_by(updated: -1).first.updated
        idea2.total_comment = idea2.comments.count
        idea2.app_ids = [ app1.id ]
        idea2.issue = unique_id
        idea2.data = unique_id
        idea2.note = unique_id
        idea2.save!

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
        expect(dest_site.id).not_to eq site.id
        expect(dest_site.name).to eq target_host_name
        expect(dest_site.domains).to include target_host_domain
        expect(dest_site.group_ids).to eq site.group_ids

        dest_layout = Cms::Layout.site(dest_site).find_by(filename: layout.filename)
        expect(dest_layout.id).not_to eq layout.id
        expect(dest_layout.name).to eq layout.name
        expect(dest_layout.user_id).to eq layout.user_id
        expect(dest_layout.html).to eq layout.html

        dest_dataset = Cms::Page.site(dest_site).find_by(filename: dataset.filename)
        expect(dest_dataset.id).not_to eq dataset.id
        expect(dest_dataset.name).to eq dataset.name

        dest_app = Cms::Page.site(dest_site).find_by(filename: app1.filename)
        expect(dest_app.id).not_to eq app1.id
        expect(dest_app.name).to eq app1.name

        Cms::Page.site(dest_site).find_by(filename: idea1.filename).tap do |dest_idea|
          dest_idea = dest_idea.becomes_with_route
          expect(dest_idea.name).to eq idea1.name
          # expect(dest_idea.layout_id).to eq dest_layout.id
          expect(dest_idea.user_id).to eq idea1.user_id
          expect(dest_idea.text).to eq idea1.text
          expect(dest_idea.category_ids).not_to eq idea1.category_ids
          expect(dest_idea.categories.pluck(:name)).to eq idea1.categories.pluck(:name)
          expect(dest_idea.area_ids).not_to eq idea1.area_ids
          expect(dest_idea.areas.pluck(:name)).to eq idea1.areas.pluck(:name)
          expect(dest_idea.dataset_ids).to eq [ dest_dataset.id ]
          expect(dest_idea.app_ids).to eq []
          expect(dest_idea.commented).to eq nil
          expect(dest_idea.total_comment).to eq 0
          expect(dest_idea.issue).to eq idea1.issue
          expect(dest_idea.data).to eq idea1.data
          expect(dest_idea.note).to eq idea1.note
          expect(dest_idea.comments.count).to eq 0
        end

        Cms::Page.site(dest_site).find_by(filename: idea2.filename).tap do |dest_idea|
          dest_idea = dest_idea.becomes_with_route
          expect(dest_idea.name).to eq idea2.name
          # expect(dest_idea.layout_id).to eq dest_layout.id
          expect(dest_idea.user_id).to eq idea2.user_id
          expect(dest_idea.text).to eq idea2.text
          expect(dest_idea.category_ids).not_to eq idea2.category_ids
          expect(dest_idea.categories.pluck(:name)).to eq idea2.categories.pluck(:name)
          expect(dest_idea.area_ids).not_to eq idea2.area_ids
          expect(dest_idea.areas.pluck(:name)).to eq idea2.areas.pluck(:name)
          expect(dest_idea.dataset_ids).to eq []
          expect(dest_idea.app_ids).to eq [ dest_app.id ]
          expect(dest_idea.commented).to eq nil
          expect(dest_idea.total_comment).to eq 0
          expect(dest_idea.issue).to eq idea2.issue
          expect(dest_idea.data).to eq idea2.data
          expect(dest_idea.note).to eq idea2.note
          expect(dest_idea.comments.count).to eq 0
        end
      end
    end
  end
end
