require 'spec_helper'
require "csv"

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:page1) { Timecop.freeze(now - 5.hours) { create :article_page, cur_site: site, cur_node: node } }
  let!(:page2) { Timecop.freeze(now - 4.hours) { create :article_page, cur_site: site, cur_node: node } }
  let(:index_path) { article_pages_path site.id, node }

  around do |example|
    perform_enqueued_jobs do
      example.run
    end
  end

  feature "#download" do
    scenario "click on download button to check in checkbox" do
      login_cms_user to: index_path
      all(".check")[1].click
      expect(page).to have_checked_field 'ids[]'

      wait_for_event_fired "turbo:frame-load" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.links.download")
        end
      end

      wait_for_event_fired "turbo:frame-load" do
        within_dialog do
          within "form#item-form" do
            click_on I18n.t("ss.links.download")
          end
        end
      end

      wait_for_download

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::FileGenTask.all.site(site).count).to eq 1
      task = Cms::FileGenTask.all.site(site).first
      expect(task.file_basename).to eq "article_pages"
      expect(File.size(task.generated_file_path)).to be > 0

      # チェックはダウンロードに影響しない
      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 2
        # updated_desc order
        csv_table[0].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page2.name
        end
        csv_table[1].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page1.name
        end
      end
    end

    scenario "with default options" do
      login_cms_user to: index_path
      wait_for_event_fired "turbo:frame-load" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.links.download")
        end
      end

      wait_for_event_fired "turbo:frame-load" do
        within_dialog do
          within "form#item-form" do
            click_on I18n.t("ss.links.download")
          end
        end
      end

      wait_for_download

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::FileGenTask.all.site(site).count).to eq 1
      task = Cms::FileGenTask.all.site(site).first
      expect(task.file_basename).to eq "article_pages"
      expect(File.size(task.generated_file_path)).to be > 0

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 2
        # updated_desc order
        csv_table[0].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page2.name
        end
        csv_table[1].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page1.name
        end
      end
    end

    scenario "with UTF-8 encoding" do
      login_cms_user to: index_path
      wait_for_event_fired "turbo:frame-load" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.links.download")
        end
      end

      wait_for_event_fired "turbo:frame-load" do
        within_dialog do
          within "form#item-form" do
            choose I18n.t("ss.options.csv_encoding.UTF-8")
            click_on I18n.t("ss.links.download")
          end
        end
      end

      wait_for_download

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::FileGenTask.all.site(site).count).to eq 1
      task = Cms::FileGenTask.all.site(site).first
      expect(task.file_basename).to eq "article_pages"
      expect(File.size(task.generated_file_path)).to be > 0

      expect(SS::Csv.detect_encoding(downloads.first)).to eq Encoding::UTF_8
      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 2
        # updated_desc order
        csv_table[0].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page2.name
        end
        csv_table[1].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page1.name
        end
      end
    end

    scenario "with Shift_JIS encoding" do
      login_cms_user to: index_path
      wait_for_event_fired "turbo:frame-load" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.links.download")
        end
      end

      wait_for_event_fired "turbo:frame-load" do
        within_dialog do
          within "form#item-form" do
            choose I18n.t("ss.options.csv_encoding.Shift_JIS")
            click_on I18n.t("ss.links.download")
          end
        end
      end

      wait_for_download

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::FileGenTask.all.site(site).count).to eq 1
      task = Cms::FileGenTask.all.site(site).first
      expect(task.file_basename).to eq "article_pages"
      expect(File.size(task.generated_file_path)).to be > 0

      expect(SS::Csv.detect_encoding(downloads.first)).to eq Encoding::CP932
      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 2
        # updated_desc order
        csv_table[0].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page2.name
        end
        csv_table[1].tap do |csv_row|
          expect(csv_row[Article::Page.t(:name)]).to eq page1.name
        end
      end
    end

    context "with truncate on" do
      let!(:page1) do
        html = "a" * (Cms::PageExporter::MAX_LENGTH + 1)
        categories = Array.new(SS::Csv::MAX_COUNT + SS::Csv::OVERFLOW_THRESHOLD + 1) do
          create :category_node_page, cur_site: site
        end
        groups = Array.new(SS::Csv::MAX_COUNT + SS::Csv::OVERFLOW_THRESHOLD + 1) do
          create :cms_group, name: "#{cms_group.name}/#{unique_id}"
        end
        Timecop.freeze(now - 5.hours) do
          create(
            :article_page, cur_site: site, cur_node: node, html: html,
            category_ids: categories.pluck(:id), group_ids: groups.pluck(:id))
        end
      end

      it do
        login_cms_user to: index_path
        wait_for_event_fired "turbo:frame-load" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.links.download")
          end
        end

        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within "form#item-form" do
              check I18n.t("ss.truncate_long_csv_value")
              click_on I18n.t("ss.links.download")
            end
          end
        end

        wait_for_download

        expect(Job::Log.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::FileGenTask.all.site(site).count).to eq 1
        task = Cms::FileGenTask.all.site(site).first
        expect(task.file_basename).to eq "article_pages"
        expect(File.size(task.generated_file_path)).to be > 0

        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 2
          # updated_desc order
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:name)]).to eq page2.name
          end
          csv_table[1].tap do |csv_row|
            expect(csv_row[Article::Page.t(:name)]).to eq page1.name
            expect(csv_row[Article::Page.t(:html)]).to end_with "a..."
            csv_row[Article::Page.t(:category_ids)].tap do |array_value|
              array = array_value.split(/\R/)
              expect(array.length).to eq SS::Csv::MAX_COUNT + 1
              expect(array[-1]).to eq I18n.t("cms.overflow_category", count: 11)
            end
            csv_row[Article::Page.t(:group_ids)].tap do |array_value|
              array = array_value.split(/\R/)
              expect(array.length).to eq SS::Csv::MAX_COUNT + 1
              expect(array[-1]).to eq I18n.t("ss.overflow_group", count: 11)
            end
          end
        end
      end
    end

    context "with truncate off" do
      let!(:page1) do
        html = "a" * (Cms::PageExporter::MAX_LENGTH + 1)
        categories = Array.new(SS::Csv::MAX_COUNT + SS::Csv::OVERFLOW_THRESHOLD + 1) do
          create :category_node_page, cur_site: site, name: "cate-#{unique_id}"
        end
        groups = Array.new(SS::Csv::MAX_COUNT + SS::Csv::OVERFLOW_THRESHOLD + 1) do
          create :cms_group, name: "#{cms_group.name}/#{unique_id}"
        end
        Timecop.freeze(now - 5.hours) do
          create(
            :article_page, cur_site: site, cur_node: node, html: html,
            category_ids: categories.pluck(:id), group_ids: groups.pluck(:id))
        end
      end

      it do
        login_cms_user to: index_path
        wait_for_event_fired "turbo:frame-load" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.links.download")
          end
        end

        wait_for_event_fired "turbo:frame-load" do
          within_dialog do
            within "form#item-form" do
              uncheck I18n.t("ss.truncate_long_csv_value")
              click_on I18n.t("ss.links.download")
            end
          end
        end

        wait_for_download

        expect(Job::Log.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        expect(Cms::FileGenTask.all.site(site).count).to eq 1
        task = Cms::FileGenTask.all.site(site).first
        expect(task.file_basename).to eq "article_pages"
        expect(File.size(task.generated_file_path)).to be > 0

        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 2
          # updated_desc order
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:name)]).to eq page2.name
          end
          csv_table[1].tap do |csv_row|
            expect(csv_row[Article::Page.t(:name)]).to eq page1.name
            expect(csv_row[Article::Page.t(:html)]).to end_with "aaa"
            csv_row[Article::Page.t(:category_ids)].tap do |array_value|
              array = array_value.split(/\R/)
              expect(array.length).to eq SS::Csv::MAX_COUNT + SS::Csv::OVERFLOW_THRESHOLD + 1
              expect(array[-1]).not_to eq I18n.t("cms.overflow_category", count: 11)
              expect(array[-1]).to start_with("cate-")
            end
            csv_row[Article::Page.t(:group_ids)].tap do |array_value|
              array = array_value.split(/\R/)
              expect(array.length).to eq SS::Csv::MAX_COUNT + SS::Csv::OVERFLOW_THRESHOLD + 1
              expect(array[-1]).not_to eq I18n.t("ss.overflow_group", count: 11)
              expect(array[-1]).to start_with("#{cms_group.name}/")
            end
          end
        end
      end
    end
  end
end
