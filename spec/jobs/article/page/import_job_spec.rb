require 'spec_helper'

describe Article::Page::ImportJob, dbscope: :example do
  let!(:site) { cms_site }

  describe ".valid_csv?" do
    context "with csv file" do
      let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_1.csv" }

      it do
        Fs::UploadedFile.create_from_file(path, basename: "spec") do |file|
          expect(Article::Page::Importer.valid_csv?(file)).to be_truthy
        end
      end
    end

    context "with pdf file" do
      let(:path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }

      it do
        Fs::UploadedFile.create_from_file(path, basename: "spec") do |file|
          expect(Article::Page::Importer.valid_csv?(file)).to be_falsey
        end
      end
    end
  end

  describe "#perform" do
    context "with Shift_JIS file" do
      let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_1.csv" }
      let(:ss_file) do
        SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
          ::FileUtils.cp(path, file.path)
        end
      end
      let(:node) do
        create :article_node_page, cur_site: site
      end

      before do
        job = Article::Page::ImportJob.bind(site_id: site.id, node_id: node.id, user_id: cms_user.id)
        expect { job.perform_now(ss_file.id) }.to output(include("import start #{ss_file.name}\n")).to_stdout
      end

      it do
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Article::Page.site(site).count).to eq 2
        expect(Article::Page.site(site).where(filename: "#{node.filename}/test_1.html")).to be_present
        expect(Article::Page.site(site).where(filename: "#{node.filename}/test_2.html")).to be_present
      end
    end

    context "with UTF-8 file" do
      let(:source_node) { create :article_node_page, cur_site: site }
      let(:layout) { create_cms_layout }
      let(:dest_node) { create :article_node_page, cur_site: site }
      let(:category_node) { create :category_node_page, cur_site: site }

      before do
        source_page

        filename = "#{unique_id}.csv"
        csv_file = SS::TempFile.create_empty!(name: filename, filename: filename, content_type: 'text/csv') do |file|
          ::File.open(file.path, "wb") do |f|
            exporter = Cms::PageExporter.new(mode: "article", site: site, criteria: Article::Page.site(site).node(source_node))
            exporter.enum_csv(encoding: "UTF-8").each do |csv_row|
              f.write(csv_row)
            end
          end
        end

        job = Article::Page::ImportJob.bind(site_id: site.id, node_id: dest_node.id, user_id: cms_user.id)
        expect { job.perform_now(csv_file.id) }.to output(include("import start #{csv_file.name}\n")).to_stdout

        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Article::Page.site(site).node(dest_node).count).to eq 1
      end

      context "basic section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100)
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.name).to eq source_page.name
            expect(page.index_name).to eq source_page.index_name
            expect(page.basename).to eq source_page.basename
            expect(page.layout).to eq source_page.layout
            expect(page.order).to eq source_page.order
          end
        end
      end

      context "meta section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            keywords: [ unique_id ], description: unique_id, summary_html: unique_id
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.keywords).to eq source_page.keywords
            expect(page.description).to eq source_page.description
            expect(page.summary_html).to eq source_page.summary_html
          end
        end
      end

      context "body section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            html: unique_id
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.html).to eq source_page.html
          end
        end
      end

      context "category section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            category_ids: [ category_node.id ]
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.category_ids).to eq source_page.category_ids
          end
        end
      end

      context "event section fields is given" do
        let(:event_dates) { %w(2019/02/02 2019/02/03 2019/02/09 2019/02/10 2019/02/16 2019/02/17) }
        let(:event_recurrence1) { { kind: "date", start_at: "2019/02/02", frequency: "daily", until_on: "2019/02/03" } }
        let(:event_recurrence2) { { kind: "date", start_at: "2019/02/09", frequency: "daily", until_on: "2019/02/10" } }
        let(:event_recurrence3) { { kind: "date", start_at: "2019/02/16", frequency: "daily", until_on: "2019/02/17" } }
        let(:event_recurrences) { [ event_recurrence1, event_recurrence2, event_recurrence3 ] }
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            event_name: unique_id, event_recurrences: event_recurrences, event_deadline: "2018/12/25 13:21"
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.event_name).to eq source_page.event_name
            expect(page.event_dates).to eq source_page.event_dates
            expect(page.event_deadline).to eq source_page.event_deadline
          end
        end
      end

      context "map section fields is given" do
        let(:map_point) do
          {
            name: unique_id, loc: [ 138.235266, 36.244941 ], text: Array.new(2) { unique_id }.join("\n"),
            image: "/assets/img/openlayers/marker3.png"
          }
        end
        let(:map_zoom_level) { rand(5..12) }
        let(:center_setting) { %w(auto designated_location).sample }
        let(:set_center_position) { "138.252924,36.204824" }
        let(:zoom_setting) { %w(auto designated_level).sample }
        let(:set_zoom_level) { rand(5..12) }
        let(:map_reference_method) { "direct" }
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            map_points: [ map_point ], map_zoom_level: map_zoom_level, center_setting: center_setting,
            set_center_position: set_center_position, zoom_setting: zoom_setting, set_zoom_level: set_zoom_level,
            map_reference_method: map_reference_method
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.map_points).to eq source_page.map_points
            expect(page.center_setting).to eq source_page.center_setting
            expect(page.set_center_position).to eq source_page.set_center_position
            expect(page.zoom_setting).to eq source_page.zoom_setting
            expect(page.set_zoom_level).to eq source_page.set_zoom_level
            expect(page.map_reference_method).to eq source_page.map_reference_method
          end
        end
      end

      context "related_pages section fields is given" do
        let(:related_page) { create :article_page, cur_site: site, cur_node: category_node }
        let(:related_page_sort) { [ "name", "filename", "updated -1" ].sample }
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            related_page_ids: [ related_page.id ], related_page_sort: related_page_sort
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.related_page_ids).to eq source_page.related_page_ids
            expect(page.related_page_sort).to eq source_page.related_page_sort
          end
        end
      end

      context "crumb section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            parent_crumb_urls: [ unique_id, unique_id ]
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.parent_crumb_urls).to eq source_page.parent_crumb_urls
          end
        end
      end

      context "contact section fields is given" do
        let(:contact_state) { %w(show hide).sample }
        let!(:source_page) do
          cms_group.update(contact_groups: [
            {
              main_state: "main", name: "name-#{unique_id}", contact_group_name: "contact_group_name-#{unique_id}",
              contact_tel: unique_tel, contact_fax: unique_tel, contact_email: unique_email,
              contact_link_url: "/#{unique_id}", contact_link_name: "link_name-#{unique_id}",
            }
          ])

          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            contact_state: contact_state, contact_group: cms_group, contact_group_contact_id: cms_group.contact_groups.first.id,
            contact_group_relation: contact_group_relation, contact_charge: unique_id, contact_tel: unique_id,
            contact_fax: unique_id, contact_email: "#{unique_id}@example.jp",
            contact_link_url: "/#{unique_id}/", contact_link_name: unique_id
          )
        end

        context "when contact_group_relation is blank" do
          let(:contact_group_relation) { nil }

          it do
            Article::Page.site(site).node(dest_node).first.tap do |page|
              expect(page.contact_state).to eq source_page.contact_state
              expect(page.contact_group_id).to eq source_page.contact_group_id
              expect(page.contact_group_contact_id).to eq cms_group.contact_groups.first.id
              expect(page.contact_group_relation).to eq contact_group_relation
              expect(page.contact_charge).to eq source_page.contact_charge
              expect(page.contact_tel).to eq source_page.contact_tel
              expect(page.contact_fax).to eq source_page.contact_fax
              expect(page.contact_email).to eq source_page.contact_email
              expect(page.contact_link_url).to eq source_page.contact_link_url
              expect(page.contact_link_name).to eq source_page.contact_link_name
            end
          end
        end

        context "when contact_group_relation is related" do
          let(:contact_group_relation) { "related" }

          it do
            Article::Page.site(site).node(dest_node).first.tap do |page|
              expect(page.contact_state).to eq source_page.contact_state
              expect(page.contact_group_id).to eq source_page.contact_group_id
              expect(page.contact_group_contact_id).to eq cms_group.contact_groups.first.id
              expect(page.contact_group_relation).to eq contact_group_relation
              cms_group.contact_groups.first.tap do |contact|
                expect(page.contact_charge).to eq contact.contact_group_name
                expect(page.contact_tel).to eq contact.contact_tel
                expect(page.contact_fax).to eq contact.contact_fax
                expect(page.contact_email).to eq contact.contact_email
                expect(page.contact_link_url).to eq contact.contact_link_url
                expect(page.contact_link_name).to eq contact.contact_link_name
              end
            end
          end
        end

        context "when contact_group_relation is unrelated" do
          let(:contact_group_relation) { "unrelated" }

          it do
            Article::Page.site(site).node(dest_node).first.tap do |page|
              expect(page.contact_state).to eq source_page.contact_state
              expect(page.contact_group_id).to eq source_page.contact_group_id
              expect(page.contact_group_contact_id).to eq cms_group.contact_groups.first.id
              expect(page.contact_group_relation).to eq contact_group_relation
              expect(page.contact_charge).to eq source_page.contact_charge
              expect(page.contact_tel).to eq source_page.contact_tel
              expect(page.contact_fax).to eq source_page.contact_fax
              expect(page.contact_email).to eq source_page.contact_email
              expect(page.contact_link_url).to eq source_page.contact_link_url
              expect(page.contact_link_name).to eq source_page.contact_link_name
            end
          end
        end
      end

      context "released section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            released: Time.zone.now.strftime("%Y/%m/%d %H:%M"),
            close_date: Time.zone.now.next_year.strftime("%Y/%m/%d %H:%M")
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.released).to eq source_page.released
            expect(page.release_date).to eq source_page.release_date
            expect(page.close_date).to eq source_page.close_date
          end
        end
      end

      context "groups section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            group_ids: cms_user.group_ids, permission_level: rand(1..3)
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.group_ids).to eq source_page.group_ids
            unless SS.config.ss.disable_permission_level
              expect(page.permission_level).to eq source_page.permission_level
            end
          end
        end
      end

      context "state section fields is given" do
        let!(:source_page) do
          Article::Page.create!(
            cur_site: site, cur_node: source_node, cur_user: cms_user,
            name: unique_id, index_name: unique_id, basename: "#{unique_id}.html", layout: layout, order: rand(1..100),
            state: %w(public ready closed).sample
          )
        end

        it do
          Article::Page.site(site).node(dest_node).first.tap do |page|
            expect(page.state).to eq source_page.state
          end
        end
      end
    end

    context "with UTF-8 without BOM file" do
      let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_4.csv" }
      let(:ss_file) do
        SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
          ::FileUtils.cp(path, file.path)
        end
      end
      let(:node) do
        create :article_node_page, cur_site: site
      end

      before do
        job = Article::Page::ImportJob.bind(site_id: site.id, node_id: node.id, user_id: cms_user.id)
        expect { job.perform_now(ss_file.id) }.to output(include("import start #{ss_file.name}\n")).to_stdout
      end

      it do
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Article::Page.site(site).count).to eq 2

        expect(Article::Page.site(site).where(filename: "#{node.filename}/test_1.html")).to be_present
        expect(Article::Page.site(site).where(filename: "#{node.filename}/test_2.html")).to be_present
      end
    end

    context "with non supported encoding file" do
      let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_5.csv" }
      let(:ss_file) do
        SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
          ::FileUtils.cp(path, file.path)
        end
      end
      let(:node) do
        create :article_node_page, cur_site: site
      end

      before do
        job = Article::Page::ImportJob.bind(site_id: site.id, node_id: node.id, user_id: cms_user.id)
        expect { job.perform_now(ss_file.id) }.to output(include("import start #{ss_file.name}\n")).to_stdout
      end

      it do
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Article::Page.site(site).count).to eq 0
        expect(Article::Page.site(site).where(filename: "#{node.filename}/test_1.html")).to be_blank
        expect(Article::Page.site(site).where(filename: "#{node.filename}/test_2.html")).to be_blank
      end
    end

    context "set category_ids" do
      let!(:site2) { create :cms_site, name: "another", host: "another", domains: "another.localhost.jp" }
      let!(:node) { create :article_node_page }

      let!(:cate1_depth1) { create(:category_node_node, name: "cate1", filename: "A") } # cate1
      let!(:cate1_depth2) { create(:category_node_node, name: "cate2", filename: "A/B") } # cate1/cate2
      let!(:cate1_depth3) { create(:category_node_page, name: "cate3", filename: "A/B/C") } # cate1/cate2/cate3

      let!(:cate2_depth1) { create(:category_node_node, name: "cate1", filename: "D") } # cate1
      let!(:cate2_depth2) { create(:category_node_node, name: "cate2", filename: "D/E") } # cate1/cate2
      let!(:cate2_depth3) { create(:category_node_page, name: "cate3", filename: "D/E/F") } # cate1/cate2/cate3
      let!(:cate2_depth4) { create(:category_node_node, name: "cate3", filename: "G") } # cate3

      let!(:cate3_depth1) { create(:category_node_node, name: "cate4", filename: "H") } # cate4
      let!(:cate3_depth2) { create(:category_node_node, name: "cate5", filename: "H/I") } # cate4/cate5
      let!(:cate3_depth3) { create(:category_node_page, name: "cate6", filename: "H/I/J") } # cate4/cate5/cate6

      let!(:facility1) { create(:facility_node_category, name: "cate1", filename: "K") } # cate1
      let!(:facility2) { create(:facility_node_category, name: "cate2", filename: "L/M") } # cate1/cate2
      let!(:facility3) { create(:facility_node_category, name: "cate3", filename: "N/O/P") } # cate1/cate2/cate3

      let!(:another_cate1_depth1) do
        # cate1
        create(:category_node_node, cur_site: site2, name: "cate1", filename: "A")
      end
      let!(:another_cate1_depth2) do
        # cate1/cate2
        create(:category_node_node, cur_site: site2, name: "cate2", filename: "A/B")
      end
      let!(:another_cate1_depth3) do
        # cate1/cate2/cate3
        create(:category_node_page, cur_site: site2, name: "cate3", filename: "A/B/C")
      end

      let(:path) { "#{Rails.root}/spec/fixtures/article/article_import_test_3.csv" }
      let(:ss_file) do
        SS::TempFile.create_empty!(name: "#{unique_id}.csv", filename: "#{unique_id}.csv", content_type: 'text/csv') do |file|
          ::FileUtils.cp(path, file.path)
        end
      end

      before do
        job = Article::Page::ImportJob.bind(site_id: site.id, node_id: node.id, user_id: cms_user.id)
        expect { job.perform_now(ss_file.id) }.to output(include("import start #{ss_file.name}\n")).to_stdout
      end

      it do
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        page1 = Article::Page.site(site).find_by(name: "page1")
        page2 = Article::Page.site(site).find_by(name: "page2")
        page3 = Article::Page.site(site).find_by(name: "page3")
        page4 = Article::Page.site(site).find_by(name: "page4")
        page5 = Article::Page.site(site).find_by(name: "page5")
        page6 = Article::Page.site(site).find_by(name: "page6")

        expect(page1.category_ids).to match_array [cate1_depth3.id, cate2_depth3.id]
        [cate1_depth3.id, cate2_depth3.id, cate1_depth2.id, cate2_depth2.id, cate1_depth1.id, cate2_depth1.id].tap do |ary|
          expect(page2.category_ids).to match_array ary
        end
        expect(page3.category_ids).to match_array [cate3_depth3.id]
        expect(page4.category_ids).to match_array [cate3_depth2.id, cate2_depth4.id]
        expect(page5.category_ids).to match_array []
        expect(page6.category_ids).to match_array []
      end
    end
  end
end
