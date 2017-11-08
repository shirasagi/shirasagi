class Gws::Share::Folder
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  #include SS::UserPermission
  include Gws::Addon::File
  include Gws::Share::DescendantsFileInfo

  store_in collection: :gws_share_folders

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :state, type: String, default: "closed"
  field :share_max_file_size, type: Integer, default: 0
  field :share_max_folder_size, type: Integer, default: 0
  attr_accessor :in_share_max_file_size_mb
  attr_accessor :in_share_max_folder_size_mb

  has_many :files, class_name: "Gws::Share::File", order: { created: -1 }, dependent: :destroy, autosave: false

  permit_params :name, :order, :share_max_file_size, :in_share_max_file_size_mb, :share_max_folder_size, :in_share_max_folder_size_mb

  before_validation :set_share_max_file_size
  before_validation :set_share_max_folder_size

  validates :name, presence: true, uniqueness: { scope: :site_id }
  validates :share_max_file_size, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }

  default_scope ->{ order_by order: 1 }

  class << self
    def search(params)
      criteria = where({})
      return criteria if params.blank?

      criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
      criteria
    end

    def create_temporary_directory(userid, root_temp_dir, temp_dir)
      Dir.glob(root_temp_dir + "/" + "#{userid}_*").each do |tmp|
        FileUtils.rm_rf(tmp) if File.exists?(tmp)
      end

      FileUtils.mkdir_p(temp_dir) unless FileTest.exist?(temp_dir)
    end

    def create_zip(zipfile, items, filename_duplicate_flag)
      Zip::File.open(zipfile, Zip::File::CREATE) do |zip_file|
        items.each do |item|
          if File.exist?(item.path)
            if filename_duplicate_flag == 0
              zip_file.add(NKF::nkf('-sx --cp932', item.name), item.path)
            elsif filename_duplicate_flag == 1
              zip_file.add(NKF::nkf('-sx --cp932',item._id.to_s + "_" + item.name), item.path)
            end
          end
        end
      end
    end

    def delete_temporary_directory(zipfile)
      file_body = Class.new do
        attr_reader :to_path

        def initialize(path)
          @to_path = path
        end

        def each
          File.open(to_path, 'rb') do |file|
            while chunk = file.read(163_84)
              yield chunk
            end
          end
        end

        def close
          FileUtils.rm_rf File.dirname(@to_path)
        end
      end
      return file_body.new(zipfile)
    end
  end

  private

  def set_share_max_file_size
    return if in_share_max_file_size_mb.blank?
    self.share_max_file_size = Integer(in_share_max_file_size_mb) * 1_024 * 1_024
  end

  def set_share_max_folder_size
    return if in_share_max_folder_size_mb.blank?
    self.share_max_folder_size = Integer(in_share_max_folder_size_mb) * 1_024 * 1_024
  end
end
