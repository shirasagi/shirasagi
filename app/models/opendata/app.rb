class Opendata::App
  include Cms::Model::Page
  include ::Workflow::Addon::Approver
  include Opendata::Addon::Appfile
  include Opendata::Addon::Category
  include Opendata::Addon::Area
  include Opendata::Addon::Dataset
  include Opendata::Reference::Member
  include Opendata::Common
  include Cms::Addon::Release
  include Contact::Addon::Page
  include Cms::Addon::RelatedPage
  include Cms::Addon::GroupPermission
  include Workflow::MemberPermission

  set_permission_name "opendata_apps"

  field :point, type: Integer, default: "0"
  field :text, type: String
  field :appurl, type: String
  field :tags, type: SS::Extensions::Words
  field :license, type: String
  field :executed, type: Integer

  has_many :points, primary_key: :app_id, class_name: "Opendata::AppPoint",
    dependent: :destroy
  embeds_ids :datasets, class_name: "Opendata::Dataset"
  has_many :ideas, primary_key: :app_id, class_name: "Opendata::Idea"

  permit_params :text, :appurl, :license, :dataset_ids, :tags, tags: []

  validates :text, presence: true
  validates :category_ids, presence: true
  validates :license, presence: true
  validate :validate_appurl

  before_save :seq_filename, if: ->{ basename.blank? }

  default_scope ->{ where(route: "opendata/app") }

  public
    def point_url
      get_url(url, "/point.html")
    end

    def point_members_url
      get_url(url, "/point/members.html")
    end

    def app_ideas_url
      get_url(url, "/ideas/show.html")
    end

    def zip_url
      get_url(url, "/zip")
    end

    def executed_show_url
      get_url(url, "/executed/show.html")
    end

    def executed_add_url
      get_url(url, "/executed/add.html")
    end

    def full_screen_url
      get_url(url, "/full/")
    end

    def file_text_url
      get_url(url, "/file_text/")
    end

    def file_index_url
      get_url(url, "/file_index/")
    end

    def contact_present?
      return false if member_id.present?
      super
    end

    def create_zip
      zip_filename = self.class.zip_dir.join("#{id}.zip").to_s
      File.unlink(zip_filename) if File.exist?(zip_filename)

      Zip::Archive.open(zip_filename, Zip::CREATE) do |ar|
        appfiles.each do |appfile|
          ar.add_file(appfile.filename.encode('cp932', invalid: :replace, undef: :replace, replace: '_'), appfile.file.path)
        end
      end
      return zip_filename
    end

  private
    def validate_filename
      @basename.blank? ? nil : super
    end

    def seq_filename
      self.filename = dirname ? "#{dirname}#{id}.html" : "#{id}.html"
    end

    def validate_appurl
      if self.appurl.present?
        if self.appfiles.present?
          errors.add :appurl, I18n.t("opendata.errors.messages.validate_appurl")
          return
        end
      end
    end

  class << self
    def to_app_path(path)
      suffix = %w(/point.html /point/members.html /ideas/show.html /zip /executed/show.html
                  /executed/add.html /full/ /full/index.html).find { |suffix| path.end_with? suffix }
      if suffix.present?
        path[0..(path.length - suffix.length - 1)] + '.html'
      else
        path.sub(/\/file_text\/.*$/, '.html').sub(/\/file_index\/.*$/, '.html')
      end
    end

    def sort_options
      [
        [I18n.t("opendata.sort_options.released"), "released"],
        [I18n.t("opendata.sort_options.popular"), "popular"],
        [I18n.t("opendata.sort_options.attention"), "attention"]
      ]
    end

    def sort_hash(sort)
      case sort
      when "released"
        { released: -1, _id: -1 }
      when "popular"
        { point: -1, _id: -1 }
      when "attention"
        { executed: -1, _id: -1 }
      else
        return { released: -1 } if sort.blank?
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
    end

    def aggregate_field(name, opts = {})
      Opendata::Common.get_aggregate_field(self, name, opts)
    end

    def aggregate_array(name, opts = {})
      Opendata::Common.get_aggregate_array(self, name, opts)
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      site = params[:site]

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword],
          :name, :text, "appfiles.name", "appfiles.filename", "appfiles.text"
      end

      criteria = criteria.keyword_in params[:keyword], :name if params[:name].present?

      criteria = criteria.where tags: params[:tag] if params[:tag].present?

      criteria = criteria.where area_ids: params[:area_id].to_i if params[:area_id].present?

      criteria = criteria.where category_ids: params[:category_id].to_i if params[:category_id].present?

      criteria = criteria.where license: params[:license] if params[:license].present?

      criteria = search_poster(params, criteria)

      criteria
    end

    def search_poster(params, criteria)
      if params[:poster].present?
        code = {}
        cond = { :workflow_member_id.exists => true } if params[:poster] == "member"
        cond = { :workflow_member_id => nil } if params[:poster] == "admin"
        criteria = criteria.where(cond)
      end
      criteria
    end

    def zip_dir
      dir = Rails.root.join('tmp', 'opendata')
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      dir
    end
  end
end
