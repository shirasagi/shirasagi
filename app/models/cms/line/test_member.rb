class Cms::Line::TestMember
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::GroupPermission

  set_permission_name "cms_line_messages", :use

  seqid :id
  field :name, type: String
  field :oauth_id, type: String

  permit_params :name, :oauth_id

  validates :name, presence: true
  validates :oauth_id, presence: true

  default_scope -> { order_by(name: 1) }

  def root_owned?(user)
    true
  end

  def private_show_path(*args)
    options = args.extract_options!
    options.merge!(site: (cur_site || site), id: id)
    helper_mod = Rails.application.routes.url_helpers
    helper_mod.cms_line_test_member_path(*args, options) rescue nil
  end

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end

    def encode_sjis(str)
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def line_members_enum(site)
      members = criteria.to_a
      Enumerator.new do |y|
        headers = %w(id name oauth_id).map { |v| self.t(v) }
        y << encode_sjis(headers.to_csv)
        members.each do |item|
          row = []
          row << item.id
          row << item.name
          row << item.oauth_id
          y << encode_sjis(row.to_csv)
        end
      end
    end
  end
end
