require 'spec_helper'

describe "inquiry_agents_nodes_form", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:node) do
    create(
      :inquiry_node_form, cur_site: site, layout_id: layout.id,
      inquiry_captcha: 'disabled', notice_state: 'disabled', reply_state: 'disabled'
    )
  end
  let!(:file) { tmp_ss_file(contents: '0123456789', user: cms_user) }
  let!(:item) { create :cms_page, cur_site: site, layout_id: layout.id, file_ids: [ file.id ] }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge(cur_site: site)
    node.reload
  end

  context "ss-3812" do
    before do
      file.reload
      expect(file.owner_item.id).to eq item.id
      expect(file.model).to eq "cms/page"
    end

    it do
      visit node.full_url

      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: file.id.to_s
        end
        click_button I18n.t('inquiry.confirm')
      end

      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find("[name='item[1]']")['value']).to eq file.id.to_s
        end
        within 'footer.send' do
          click_button I18n.t('inquiry.submit')
        end
      end

      expect { file.reload }.not_to raise_error
      expect(file.owner_item.id).to eq item.id
      expect(file.model).to eq "cms/page"

      expect(Inquiry::Answer.site(site).count).to eq 1
      Inquiry::Answer.first.destroy

      expect { file.reload }.not_to raise_error
      expect(file.owner_item.id).to eq item.id
      expect(file.model).to eq "cms/page"
    end
  end
end
