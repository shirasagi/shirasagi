require 'spec_helper'

describe SS::File, dbscope: :example do
  context "with empty" do
    subject { described_class.new }
    its(:valid?) { is_expected.to be_falsey }
  end

  context "with valid item" do
    subject { create :ss_file }
    its(:valid?) { is_expected.to be_truthy }
    its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
    its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{subject.name}" }
    its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/thumb/#{subject.name}" }
    its(:public?) { is_expected.to be_falsey }
    its(:public_path) { is_expected.to be_nil }
    its(:full_url) { is_expected.to be_nil }
    its(:name) { is_expected.to eq 'logo.png' }
    its(:humanized_name) { is_expected.to eq 'logo (PNG 11.5KB)' }
    its(:download_filename) { is_expected.to eq 'logo.png' }
    its(:basename) { is_expected.to eq 'logo.png' }
    its(:extname) { is_expected.to eq 'png' }
    its(:image?) { is_expected.to be_truthy }
  end

  context "with item related to site" do
    let(:site) { ss_site }
    subject { create :ss_file, site_id: site.id }
    its(:valid?) { is_expected.to be_truthy }
    its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
    its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{subject.name}" }
    its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/thumb/#{subject.name}" }
    its(:public?) { is_expected.to be_falsey }
    its(:public_path) { is_expected.to eq "#{site.root_path}/fs/#{subject.id}/_/#{subject.filename}" }
    its(:full_url) { is_expected.to eq "http://#{site.domain}/fs/#{subject.id}/_/#{subject.filename}" }
    its(:name) { is_expected.to eq 'logo.png' }
    its(:humanized_name) { is_expected.to eq 'logo (PNG 11.5KB)' }
    its(:download_filename) { is_expected.to eq 'logo.png' }
    its(:basename) { is_expected.to eq 'logo.png' }
    its(:extname) { is_expected.to eq 'png' }
    its(:image?) { is_expected.to be_truthy }
  end

  context "with item related to sub-dir site" do
    let(:site0) { ss_site }
    let(:site1) { create(:ss_site_subdir, domains: site0.domains, parent_id: site0.id) }
    subject { create :ss_file, site_id: site1.id }
    its(:valid?) { is_expected.to be_truthy }
    its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
    its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{subject.name}" }
    its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/thumb/#{subject.name}" }
    its(:public?) { is_expected.to be_falsey }
    its(:public_path) { is_expected.to eq "#{site0.root_path}/fs/#{subject.id}/_/#{subject.filename}" }
    its(:full_url) { is_expected.to eq "http://#{site0.domain}/fs/#{subject.id}/_/#{subject.filename}" }
    its(:name) { is_expected.to eq 'logo.png' }
    its(:humanized_name) { is_expected.to eq 'logo (PNG 11.5KB)' }
    its(:download_filename) { is_expected.to eq 'logo.png' }
    its(:basename) { is_expected.to eq 'logo.png' }
    its(:extname) { is_expected.to eq 'png' }
    its(:image?) { is_expected.to be_truthy }
  end

  describe "#uploaded_file" do
    let(:file) { create :ss_file }
    subject { file.uploaded_file }
    its(:original_filename) { is_expected.to eq file.basename }
    its(:content_type) { is_expected.to eq file.content_type }
    # its(:tempfile) { is_expected.not_to be_nil }
    # its(:headers) { is_expected.not_to be_nil }
    its(:path) { is_expected.not_to be_nil }
    its(:size) { is_expected.to eq file.size }
    its(:eof?) { is_expected.to be_falsey }
    its(:read) { expect(subject.respond_to?(:read)).to be_truthy }
    its(:open) { expect(subject.respond_to?(:open)).to be_truthy }
    its(:close) { expect(subject.respond_to?(:close)).to be_truthy }
    its(:rewind) { expect(subject.respond_to?(:rewind)).to be_truthy }
  end

  describe "shirasagi-434" do
    before do
      @tmpdir = ::Dir.mktmpdir
      @file_path = "#{@tmpdir}/#{filename}"
      File.open(@file_path, "wb") do |file|
        file.write [1]
      end
    end

    after do
      ::FileUtils.rm_rf(@tmpdir)
    end

    before do
      # we need custom setting for jtd
      @save_config = SS.config.env.mime_type_map
      SS.config.replace_value_at(:env, :mime_type_map, mime_type_map)
    end

    after do
      SS.config.replace_value_at(:env, :mime_type_map, @save_config)
    end

    subject do
      file = SS::File.new model: "article/page"
      Fs::UploadedFile.create_from_file(@file_path, basename: "spec", content_type: "application/octet-stream") do |f|
        file.in_file = f
        file.save!
        file.in_file = nil
      end
      file.reload
      file
    end

    context "when pdf file is uploaded with application/octet-stream" do
      let(:filename) { "a.pdf" }
      let(:mime_type_map) { {} }
      its(:content_type) { is_expected.to eq "application/pdf" }
    end

    context "when js file is uploaded with application/octet-stream" do
      let(:filename) { "a.js" }
      let(:mime_type_map) { {} }
      its(:content_type) { is_expected.to eq "application/javascript" }
    end

    context "when jtd file is uploaded with application/octet-stream" do
      let(:filename) { "a.jtd" }
      let(:mime_type_map) { { "jtd" => "application/x-js-taro" } }
      its(:content_type) { is_expected.to eq "application/x-js-taro" }
    end

    context "when wmv file is uploaded with application/octet-stream" do
      let(:filename) { "a.wmv" }
      let(:mime_type_map) { { "wmv" => "video/x-ms-wmv" } }
      its(:content_type) { is_expected.to eq "video/x-ms-wmv" }
    end
  end

  describe "#validate_size" do
    let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
    let(:test_file) { Fs::UploadedFile.create_from_file(test_file_path, basename: "spec") }

    after do
      test_file.close unless test_file.closed?
    end

    subject do
      file = SS::File.new model: "article/page"
      file.in_file = test_file
      file
    end

    context "when max_filesize is limited" do
      before do
        @save_config = SS.config.env.max_filesize
        SS.config.replace_value_at(:env, :max_filesize, 50)
      end

      after do
        SS.config.replace_value_at(:env, :max_filesize, @save_config)
      end

      it do
        expect(subject.save).to be_falsey
        expect(subject.errors[:base]).not_to be_empty
        expect(subject.errors[:base].first).to include("logo.png", "サイズが大きすぎます", "制限値: 50バイト")
      end
    end

    context "when max_filesize_ext is limited" do
      before do
        @save_config = SS.config.env.max_filesize_ext
        SS.config.replace_value_at(:env, :max_filesize_ext, { "png" => 23 })
      end

      after do
        SS.config.replace_value_at(:env, :max_filesize_ext, @save_config)
      end

      it do
        expect(subject.save).to be_falsey
        expect(subject.errors[:base]).not_to be_empty
        expect(subject.errors[:base].first).to include("logo.png", "サイズが大きすぎます", "制限値: 23バイト")
      end
    end
  end

  describe "shirasagi-1066" do
    let(:single_frame_image) { "#{::Rails.root}/spec/fixtures/ss/file/keyvisual.jpg" }
    let(:multi_frame_image) { "#{::Rails.root}/spec/fixtures/ss/file/keyvisual.gif" }

    context "when save single frame image" do
      subject do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(single_frame_image) do |f|
          file.in_file = f
          file.save!
          file.in_file = nil
        end
        file.reload
        file
      end

      it "#save_file" do
        list = Magick::ImageList.new
        list.from_blob(subject.read)
        expect(list.size).to eq 1
      end
    end

    context "when save single frame image with resizing" do
      subject do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(single_frame_image) do |f|
          file.in_file = f
          file.resizing = [320, 240]
          file.save!
          file.in_file = nil
        end
        file.reload
        file
      end

      it "#save_file" do
        list = Magick::ImageList.new
        list.from_blob(subject.read)
        expect(list.size).to eq 1
      end
    end

    context "when save multi frame image" do
      subject do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(multi_frame_image) do |f|
          file.in_file = f
          file.save!
          file.in_file = nil
        end
        file.reload
        file
      end

      it "#save_file" do
        list = Magick::ImageList.new
        list.from_blob(subject.read)
        expect(list.size).to eq 5
      end
    end

    context "when save multi frame image with resizing" do
      subject do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(multi_frame_image) do |f|
          file.in_file = f
          file.resizing = [320, 240]
          file.save!
          file.in_file = nil
        end
        file.reload
        file
      end

      it "#save_file" do
        list = Magick::ImageList.new
        list.from_blob(subject.read)
        expect(list.size).to eq 5
      end
    end
  end

  describe "#copy" do
    context "when non-image file is given" do
      let(:src) do
        file = SS::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy }

      it do
        expect(src.thumb).to be_blank

        expect(copy.id).not_to eq src.id
        expect(copy.name).to eq src.name
        expect(copy.filename).to eq src.filename
        expect(copy.content_type).to eq src.content_type
        expect(copy.size).to eq src.size
        expect(copy.model).to eq "ss/temp_file"
        expect(copy.thumb).to be_nil
      end
    end

    context "when non-image file is given" do
      let(:src) do
        file = SS::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/ss/logo.png") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy }

      it do
        expect(src.thumb).not_to be_blank

        expect(copy.id).not_to eq src.id
        expect(copy.name).to eq src.name
        expect(copy.filename).to eq src.filename
        expect(copy.content_type).to eq src.content_type
        expect(copy.size).to eq src.size
        expect(copy.model).to eq "ss/temp_file"
        expect(copy.thumb.id).not_to eq src.thumb.id
      end
    end

    context "when a file copies from one user to other user and specific node" do
      let(:site) { create(:cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp") }
      let(:group) { create(:cms_group, name: unique_id) }
      let(:user1) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
      let(:user2) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
      let(:node) { create(:article_node_page, cur_site: site) }
      let(:src) do
        tmp_ss_file(
          Cms::File,
          site: site, user: user1, model: "cms/file", contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
          group_ids: user1.group_ids
        )
      end

      it do
        copy = src.copy(cur_user: user2, cur_site: site, cur_node: node)

        expect(copy).to be_a(Cms::TempFile)
        expect(copy.id).not_to eq src.id
        expect(copy.name).to eq src.name
        expect(copy.filename).to eq src.filename
        expect(copy.content_type).to eq src.content_type
        expect(copy.size).to eq src.size
        expect(copy.model).to eq "ss/temp_file"
        expect(copy.user_id).to eq user2.id
        expect(copy.node_id).to eq node.id
      end
    end
  end

  describe "#copy_if_necessary" do
    context "when ss/file is given" do
      let(:src) do
        file = SS::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy_if_necessary }

      it do
        expect(copy).to eq src
      end
    end

    context "when ss/user_file is given" do
      let(:src) do
        file = SS::UserFile.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/user_file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy_if_necessary }

      it do
        expect(copy).not_to eq src
      end
    end

    context "when cms/file is given" do
      let(:site) { create :cms_site }
      let(:src) do
        file = Cms::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.cur_site = site
          file.in_file = upload_file
          file.model = "cms/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy_if_necessary }

      it do
        expect(copy).not_to eq src
      end
    end
  end

  describe "what ss/file exports to liquid" do
    let(:assigns) { {} }
    let(:registers) { {} }
    subject { file.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    context "with image file" do
      let!(:file) { create :ss_file }

      it do
        expect(subject.name).to eq file.name
        expect(subject.extname).to eq file.extname
        expect(subject.size).to eq file.size
        expect(subject.humanized_name).to eq file.humanized_name
        expect(subject.filename).to eq file.filename
        expect(subject.basename).to eq file.basename
        expect(subject.url).to eq file.url
        expect(subject.thumb_url).to be_present
        expect(subject.thumb_url).to eq file.thumb_url
        expect(subject.image?).to be_truthy
      end
    end

    context "with pdf file" do
      let(:path) { Rails.root.join("spec/fixtures/ss/shirasagi.pdf") }
      let!(:file) do
        Fs::UploadedFile.create_from_file(path, content_type: 'application/pdf') do |file|
          create :ss_file, in_file: file
        end
      end

      it do
        expect(subject.name).to eq file.name
        expect(subject.extname).to eq file.extname
        expect(subject.size).to eq file.size
        expect(subject.humanized_name).to eq file.humanized_name
        expect(subject.filename).to eq file.filename
        expect(subject.basename).to eq file.basename
        expect(subject.url).to eq file.url
        expect(subject.thumb_url).to be_blank
        expect(subject.image?).to be_falsey
      end
    end
  end

  describe "#download_filename" do
    context "when name is with ext" do
      subject { tmp_ss_file(contents: '0123456789', basename: "text.txt") }

      its(:download_filename) { is_expected.to eq "text.txt" }
    end

    context "when name is without ext" do
      subject { tmp_ss_file(contents: '0123456789', basename: "text") }

      its(:download_filename) { is_expected.to eq "text" }
    end

    context "when name ends with period" do
      subject { tmp_ss_file(contents: '0123456789', basename: "text.") }

      its(:download_filename) { is_expected.to eq "text" }
    end
  end

  describe "#shrink_image_to" do
    let(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg") }

    before do
      expect(ss_file.image_dimension).to eq [ 712, 210 ]
    end

    context "shrink" do
      it do
        prev_size = ss_file.size
        expect(ss_file.shrink_image_to(100, 100)).to be_truthy

        ss_file.reload
        expect(ss_file.size).to be < prev_size
        expect(ss_file.image_dimension).to eq [ 100, 29 ]
      end
    end

    context "expand" do
      it do
        prev_size = ss_file.size
        expect(ss_file.shrink_image_to(1000, 1000)).to be_truthy

        ss_file.reload
        expect(ss_file.size).to eq prev_size
        expect(ss_file.image_dimension).to eq [ 712, 210 ]
      end
    end
  end
end
