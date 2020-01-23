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

      csv = ::SS::ChunkReader.new(page.html).to_a.join
      csv = csv.encode("UTF-8", "SJIS")
      csv = ::CSV.parse(csv, headers: true)

      expect(csv.length).to eq 1
      expect(csv.headers).to include(Gws::UserTitle.t(:code), Gws::UserTitle.t(:name))
      expect(csv[0][Gws::UserTitle.t(:code)]).to eq item.code
      expect(csv[0][Gws::UserTitle.t(:name)]).to eq item.name
      expect(csv[0][Gws::UserTitle.t(:remark)]).to eq item.remark
      expect(csv[0][Gws::UserTitle.t(:order)]).to eq item.order.to_s
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
        expect(log.logs).to include(include('INFO -- : Started Job'))
        expect(log.logs).to include(include('INFO -- : Completed Job'))
      end

      expect(Gws::UserTitle.site(site).count).to eq 1
      Gws::UserTitle.site(site).first.tap do |title|
        expect(title.code).to eq item.code
        expect(title.name).to eq item.name
      end
    end
  end
end
