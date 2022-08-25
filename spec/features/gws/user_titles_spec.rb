require 'spec_helper'

describe "gws_user_titles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_user_titles_path site }

  context "with auth" do
    let!(:item) { create :ss_user_title, group_id: gws_user.group_ids.first }

    before { login_gws_user }

    it_behaves_like 'crud flow'
  end

  describe "#download_all" do
    let!(:item) { create :gws_user_title }

    before { login_gws_user }

    it do
      visit index_path
      expect(page).to have_css(".list-items", text: item.name)

      click_on I18n.t("ss.links.download")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      I18n.with_locale(I18n.default_locale) do
        csv_source = ::SS::ChunkReader.new(page.html).to_a.join
        SS::Csv.open(StringIO.new(csv_source)) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          expect(csv_table.headers).to include(Gws::UserTitle.t(:code), Gws::UserTitle.t(:name))
          expect(csv_table[0][Gws::UserTitle.t(:code)]).to eq item.code
          expect(csv_table[0][Gws::UserTitle.t(:name)]).to eq item.name
          expect(csv_table[0][Gws::UserTitle.t(:remark)]).to eq item.remark
          expect(csv_table[0][Gws::UserTitle.t(:order)]).to eq item.order.to_s
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/user_titles"
        expect(history.path).to eq download_all_gws_user_titles_path(site: site)
        expect(history.action).to eq "download_all"
      end
    end
  end

  describe "#import" do
    let(:site1) { create :gws_group }
    let!(:item) { create :gws_user_title, cur_site: site1 }

    before do
      @tmpfile = tmpfile(binary: true) do |file|
        enumerable = Gws::UserTitle.site(site1).enum_csv(encoding: "UTF-8")
        enumerable.each do |csv|
          file.write(csv)
        end
      end

      login_gws_user
    end

    it do
      visit index_path
      click_on I18n.t("ss.links.import")
      within "form#item-form" do
        attach_file "item[in_file]", @tmpfile
        perform_enqueued_jobs do
          click_on I18n.t("ss.buttons.import")
        end
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.started_import"))

      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::UserTitle.site(site).count).to eq 1
      Gws::UserTitle.site(site).first.tap do |title|
        expect(title.code).to eq item.code
        expect(title.name).to eq item.name
      end
    end
  end
end
