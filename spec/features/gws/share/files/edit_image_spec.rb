require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }
  let(:index_path) { gws_share_folder_files_path site, folder }

  before { login_gws_user }

  def extract_image_info(filepath)
    image = MiniMagick::Image.open(filepath)
    if MiniMagick.graphicsmagick?
      image_details = image.details
      image_class_type = image_details["Class"]
      image_depth = image_details["Depth"]
    else
      image_data = image.data
      image_class_type = image_data["class"]
      image_depth = "#{image_data["depth"]}-bits"
    end

    {
      filename: ::File.basename(filepath),
      format: image.type,
      width: image.width,
      height: image.height,
      class_type: image_class_type,
      depth: image_depth,
      # colors: img.number_colors,
      size: image.size,
      resolution: { x: image.height[0], y: image.height[1] }
    }
  ensure
    image.destroy! if image
  end

  context "when editing image" do
    shared_examples "rotate image" do
      it do
        before_info = extract_image_info(item.path)

        folder.update_folder_descendants_file_info
        folder.reload
        expect(folder.descendants_files_count).to eq 1
        expect(folder.descendants_total_file_size).to eq item.size

        visit index_path
        within ".tree-navi" do
          expect(page).to have_css(".item-name", text: folder.name)
        end
        click_on item.name
        click_on I18n.t("ss.links.edit")

        within "form#item-form" do
          # rotate image
          first(".btn-rotate-left").click
          first(".btn-submit-crop").click

          click_on I18n.t("ss.buttons.save")
        end

        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_content(folder.name)

        after_info = extract_image_info(item.path)
        expect(after_info).not_to eq before_info

        folder.reload
        item.reload
        expect(folder.descendants_files_count).to eq 1
        expect(folder.descendants_total_file_size).to eq item.size
      end
    end

    shared_examples "with png and jpg" do
      context "with png" do
        let!(:item) do
          Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/webapi/replace.png") do |f|
            create(:gws_share_file, folder_id: folder.id, category_ids: [category.id], in_file: f)
          end
        end

        include_context "rotate image"
      end

      context "with jpg" do
        let!(:item) do
          Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg") do |f|
            create(:gws_share_file, folder_id: folder.id, category_ids: [category.id], in_file: f)
          end
        end

        include_context "rotate image"
      end
    end

    context "with ImageMagick6" do
      around do |example|
        MiniMagick.with_cli(:imagemagick) do
          example.run
        end
      end

      include_context "with png and jpg"
    end

    context "with GraphicsMagick" do
      around do |example|
        MiniMagick.with_cli(:graphicsmagick) do
          example.run
        end
      end

      include_context "with png and jpg"
    end
  end
end
