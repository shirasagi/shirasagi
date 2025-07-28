require 'spec_helper'

describe "gws_shared_address_management_addresses", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:member) { create :gws_user }
  let(:address_group) { create :gws_shared_address_group }
  let(:index_path) { gws_shared_address_management_addresses_path(site) }

  context "with auth" do
    let!(:item) { create :gws_shared_address_address, member_id: member.id, address_group_id: address_group.id }

    before { login_gws_user }

    it_behaves_like 'crud flow'

    describe "download" do
      it do
        visit index_path
        click_link I18n.t('ss.links.download')
        within "form#item-form" do
          click_on I18n.t('ss.buttons.download')
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          SS::Csv.open(downloads.first) do |csv|
            csv_table = csv.read
            expect(csv_table.length).to eq 1
            expect(csv_table[0][Gws::SharedAddress::Address.t(:member_id)]).to eq item.member.uid
            expect(csv_table[0][Gws::SharedAddress::Address.t(:address_group_id)]).to eq item.address_group.name
            expect(csv_table[0][Gws::SharedAddress::Address.t(:name)]).to eq item.name
            expect(csv_table[0][Gws::SharedAddress::Address.t(:kana)]).to eq item.kana
            expect(csv_table[0][Gws::SharedAddress::Address.t(:company)]).to eq item.company
            expect(csv_table[0][Gws::SharedAddress::Address.t(:title)]).to eq item.title
            expect(csv_table[0][Gws::SharedAddress::Address.t(:tel)]).to eq item.tel
            expect(csv_table[0][Gws::SharedAddress::Address.t(:email)]).to eq item.email
            expect(csv_table[0][Gws::SharedAddress::Address.t(:memo)]).to eq item.memo
          end
        end

        expect(Gws::History.all.count).to be > 1
        Gws::History.all.reorder(created: -1).first.tap do |history|
          expect(history.severity).to eq "info"
          expect(history.controller).to eq "gws/shared_address/management/addresses"
          expect(history.path).to eq download_all_gws_shared_address_management_addresses_path(site: site)
          expect(history.action).to eq "download_all"
        end
      end
    end

    describe "download template" do
      it do
        visit index_path
        click_on I18n.t('ss.links.import')
        click_on I18n.t('ss.links.download_template')

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          SS::Csv.open(downloads.first) do |csv|
            csv_table = csv.read
            expect(csv_table.length).to eq 0
            %i[id member_id address_group_id name kana company title tel email memo].each do |k|
              expect(csv_table.headers).to include(Gws::SharedAddress::Address.t(k))
            end
          end
        end
      end
    end
  end

  describe "import" do
    let(:name) { unique_id }
    let(:kana) { unique_id }
    let(:company) { unique_id }
    let(:title) { unique_id }
    let(:tel) { unique_id }
    let(:email) { "#{unique_id}@#{unique_id}.example.jp" }
    let(:memo) { unique_id }
    let(:csv) do
      I18n.with_locale(I18n.default_locale) do
        ::CSV.generate do |data|
          data << Gws::SharedAddress::Address.new.send(:export_field_names)
          data << [
            nil,
            member.uid,
            address_group.name,
            name,
            kana,
            company,
            title,
            tel,
            email,
            memo
          ]
        end
      end
    end
    let(:csv_file) do
      tmpfile(extname: ".csv", binary: true) { |f| f.write(csv.encode("SJIS", invalid: :replace, undef: :replace)) }
    end
    before { login_gws_user }

    it do
      visit index_path
      click_on I18n.t('ss.links.import')
      within "form#item-form" do
        attach_file "item[in_file]", csv_file
        click_on I18n.t('ss.import')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::SharedAddress::Address.all).to have(1).items
      item = Gws::SharedAddress::Address.all.first
      expect(item.member_id).to eq member.id
      expect(item.address_group_id).to eq address_group.id
      expect(item.name).to eq name
      expect(item.kana).to eq kana
      expect(item.company).to eq company
    end
  end
end
