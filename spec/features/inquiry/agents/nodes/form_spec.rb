require 'spec_helper'

describe "inquiry_agents_nodes_form", dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :inquiry_node_form, site: site, inquiry_captcha: 'disabled' }

  before do
    node.columns.create! attributes_for(:inquiry_column1).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column2).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column3).reverse_merge({cur_site: site})
    node.reload
  end

  context "when pc site is accessed" do
    let(:index_url) { ::URI.parse "http://#{site.domain}/#{node.filename}/"}

    it do
      visit index_url
      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in "item[3]", with: "shirasagi@example.jp"
        end
        click_button "確認画面へ"
      end

      expect(status_code).to eq 200
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'shirasagi@example.jp'
        end
        # within 'div.simple-captcha' do
        #   fill_in "answer[captcha]", with: "xxxx"
        # end
        within 'footer.send' do
          click_button "送信する"
        end
      end

      expect(status_code).to eq 200
      expect(find('div.inquiry-sent').text).to eq node.inquiry_sent_html.gsub(/<.*?>/, '')
    end
  end

  context "when mobile site is accessed" do
    let(:index_url) { ::URI.parse "http://#{site.domain}#{site.mobile_location}/#{node.filename}/"}

    it do
      visit index_url
      expect(status_code).to eq 200
      # mobile モードの場合、form の action は /mobile/ で始まる
      expect(find('form')['action']).to start_with "#{site.mobile_location}/#{node.filename}/"
      within 'div.inquiry-form' do
        within 'div.columns' do
          fill_in "item[1]", with: "シラサギ太郎"
          fill_in "item[2]", with: "株式会社シラサギ"
          fill_in "item[3]", with: "shirasagi@example.jp"
        end
        click_button "確認画面へ"
      end

      expect(status_code).to eq 200
      # mobile モードの場合、/mobile/ で始まるはず
      expect(current_path).to start_with "#{site.mobile_location}/#{node.filename}/"
      # mobile モードの場合、form の action は /mobile/ で始まる
      expect(find('form')['action']).to start_with "#{site.mobile_location}/#{node.filename}/"
      within 'div.inquiry-form' do
        within 'div.columns' do
          expect(find('#item_1')['value']).to eq 'シラサギ太郎'
          expect(find('#item_2')['value']).to eq '株式会社シラサギ'
          expect(find('#item_3')['value']).to eq 'shirasagi@example.jp'
        end
        # mobile モードの場合 <footer> タグが <div> タグに置換されているはず
        within 'div.tag-footer' do
          click_button "送信する"
        end
      end

      expect(status_code).to eq 200
      # mobile モードの場合、/mobile/ で始まるはず
      expect(current_path).to start_with "#{site.mobile_location}/#{node.filename}/"
      expect(find('div.inquiry-sent').text).to eq node.inquiry_sent_html.gsub(/<.*?>/, '')
    end
  end
end
