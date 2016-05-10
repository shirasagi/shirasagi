require 'spec_helper'

describe Sys::Copy, type: :model, dbscope: :example do
  subject(:model) { Sys::Copy }

  describe '#run_copy' do

    # for app/models/concerns/sys/site_copy/nodes.rb copy_nodes_for_dupcms & copy_file_dir
    def check_nodes
      src_site_dir = Rails.public_path.to_s+'/sites/' + @src_site.host.split('').join('/') + '/_'
      dest_site_dir = Rails.public_path.to_s+'/sites/' + @dest_site.host.split('').join('/') + '/_'

      source = Cms::Node.where(site_id: @src_site.id)
      print "number of nodes: " + source.count.to_s + "\n"
      source.each do |item|
        next if ["facility/location", "facility/category", "facility/service"].include?(item.route)
        next if ["facility/search", "facility/node"].include?(item.route)
        next if ["category/node", "category/page"].include?(item.route)

        dest_item = Cms::Node.where(site_id: @dest_site.id, filename: item.filename).one
        unless dest_item
          return false
        end

        next if item.route != 'uploader/file'

        subject_dir = src_site_dir + "/" + dest_item.filename
        check_dir = dest_site_dir + "/" + dest_item.filename

        Dir.exist?(subject_dir) && Dir.entries(subject_dir).each do |filename|
          next if /^(\.|\.\.)$/ =~ filename
          return false unless File.exist?(check_dir + "/" + filename)
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/article.rb create_dup_banner_for_dup_site
    def check_banners
      source = Cms::Page.where(site_id: @src_site.id, route: "ads/banner")
      print "number of banners: " + source.count.to_s + "\n"
      source.each do |item|
        unless Cms::Page.where(site_id: @dest_site.id, filename: item.filename).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/article.rb create_dup_facility_for_dup_site
    def check_facilities
      source = Cms::Page.where(site_id: @src_site.id, route: /^facility\//)
      print "number of facilities: " + source.count.to_s + "\n"
      source.each do |item|
        unless Cms::Page.where(site_id: @dest_site.id, route: item.route, filename: item.filename).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/article.rb create_dup_key_visuals_for_dup_site & clone_file
    def check_key_visuals
      source = KeyVisual::Image.where(site_id: @src_site.id, route: "key_visual/image")
      print "number of key_visuals: " + source.count.to_s + "\n"
      source.each do |item|
        dest_item = KeyVisual::Image.where(site_id: @dest_site.id, route: item.route, filename: item.filename).one
        unless dest_item
          return false
        end
        unless SS::File.where(id: dest_item.file_id).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/article.rb create_dup_cms_page2_for_dup_site & clone_files
    def check_pages
      source = Cms::Page.where(site_id: @src_site.id,
          :route.nin => ["cms/page", "ads/banner", "facility/image", "key_visual/image"])
      print "number of pages: " + source.count.to_s + "\n"
      source.each do |item|
        dest_item = Cms::Page.where(site_id: @dest_site.id, route: item.route, filename: item.filename).one
        unless dest_item
          return false
        end
        dest_item.file_ids.each do |file_id|
          unless SS::File.where(id: file_id).count == 1
            return false
          end
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/cms_pages.rb copy_cms_pages
    def check_cms_pages
      source = Cms::Page.where(site_id: @src_site.id, route: "cms/page")
      print "number of cms pages: " + source.count.to_s + "\n"
      source.each do |item|
        unless Cms::Page.where(site_id: @dest_site.id, route: item.route, filename: item.filename).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/cms_layout.rb copy_cms_layout
    def check_layouts
      source = Cms::Layout.where(site_id: @src_site.id)
      print "number of layouts: " + source.count.to_s + "\n"
      source.each do |item|
        unless Cms::Layout.where(site_id: @dest_site.id, filename: item.filename).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/cms_parts.rb copy_cms_parts
    def check_cms_parts
      source = Cms::Part.where(site_id: @src_site.id)
      print "number of cms parts: " + source.count.to_s + "\n"
      source.each do |item|
        unless Cms::Part.where(site_id: @dest_site.id, filename: item.filename).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/dictionaries.rb copy_dictionaries
    def check_dictionaries
      source = Kana::Dictionary.where(site_id: @src_site.id)
      print "number of dictionaries: " + source.count.to_s + "\n"
      source.each do |item|
        unless Kana::Dictionary.where(site_id: @dest_site.id, name: item.name).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/roles.rb copy_roles
    def check_roles
      source = Cms::Role.where(site_id: @src_site.id)
      print "number of roles: " + source.count.to_s + "\n"
      source.each do |item|
        unless Cms::Role.where(site_id: @dest_site.id, name: item.name).count == 1
          return false
        end
      end
      true
    end

    # for app/models/concerns/sys/site_copy/templates.rb copy_templates
    def check_templates
      source = Cms::EditorTemplate.where(site_id: @src_site.id)
      print "number of templates: " + source.count.to_s + "\n"
      source.each do |item|
        unless Cms::EditorTemplate.where(site_id: @dest_site.id, name: item.name).count == 1
          return false
        end
      end
      true
    end

    before do
      load 'spec/fixtures/sys/copy/data.rb'
    end

    it 'normal test' do
      @src_site = Cms::Site.where(host: 'copy_test').first
      params = {
        "@copy_run" => {
          "copy_site" => @src_site.id,
          "name" => "SiteName",
          "host" => "hostname",
          "domains" => "hostname.local",
          "article" => "1",
          "files" => "1",
          "editor_templates" => "1",
          "dictionaries" => "1"
        }
      }
      model.new.run_copy(params)
      @dest_site = Cms::Site.where(host: params['@copy_run']['host']).one

      expect(@dest_site.host).to eq 'hostname'
      expect(check_nodes).to eq true
      expect(check_layouts).to eq true
      expect(check_banners).to eq true
      expect(check_facilities).to eq true
      expect(check_key_visuals).to eq true
      expect(check_pages).to eq true
      expect(check_cms_pages).to eq true
      expect(check_cms_parts).to eq true
      expect(check_dictionaries).to eq true
      expect(check_roles).to eq true
      expect(check_templates).to eq true
    end
  end

  describe 'validate' do
    it 'nil check' do
      copy = model.new
      copy.valid?
      messages = copy.errors.messages
      expect(messages[:name]).not_to eq nil
      expect(messages[:host]).not_to eq nil
      expect(messages[:domains]).not_to eq nil
      expect(messages[:copy_site]).not_to eq nil
    end
  end
end
