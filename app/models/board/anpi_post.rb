class Board::AnpiPost
  include Board::Model::AnpiPost
  include Board::Addon::PublicScope
  include Board::Addon::MapPoint
  include Board::Addon::GooglePersonFinder
  include SS::Reference::Site
  include SS::Reference::User
  include Cms::Reference::Member
  include Board::Addon::AnpiPostPermission

  attr_accessor :cur_node

  before_validation :copy_basic_attributes
  validate :validate_text, if: -> { @cur_node && @cur_node.text_size_limit != 0 }

  permit_params :member_id

  class << self
    public
      def to_csv
        CSV.generate do |data|
          data << %w(name kana tel addr sex age email text member_id public_scope point).map { |k| t k }
          criteria.each do |item|
            line = []
            line << item.name
            line << item.kana
            line << item.tel
            line << item.addr
            line << item.label(:sex)
            line << item.age
            line << item.email
            line << item.text
            line << item.member.name
            line << item.label(:public_scope)
            line << "#{item.point.loc.lat},#{item.point.loc.lng}"
            data << line
          end
        end
      end

      def search(params = {})
        criteria = self.where({})
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.search_text params[:name]
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :name, :kana, :tel, :addr, :age, :email
        end
        criteria
      end

      def and_member_group(group)
        self.in(member_id: group.enabled_members.map(&:id))
      end

      def and_owned_by(member)
        self.in(member_id: member.id)
      end
  end

  private
    def copy_basic_attributes
      return if @cur_member.blank?

      self.name ||= @cur_member.name
      self.email ||= @cur_member.email
      self.kana ||= @cur_member.kana if @cur_member.respond_to?(:kana) && @cur_member.kana.present?
      self.tel ||= @cur_member.tel if @cur_member.respond_to?(:tel) && @cur_member.tel.present?
      self.addr ||= @cur_member.addr if @cur_member.respond_to?(:addr) && @cur_member.addr.present?
      self.sex ||= @cur_member.sex if @cur_member.respond_to?(:sex) && @cur_member.sex.present?
      self.age ||= @cur_member.addr if @cur_member.respond_to?(:age) && @cur_member.age.present?
    end

    def text_size_limit
      @cur_node.try(:text_size_limit)
    end

    # def valid_with_captcha?(node)
    #   node.captcha_enabled? ? super() : true
    # end

    def validate_text
      return if text.blank?
      return unless limit = text_size_limit
      errors.add :text, :too_long, count: limit if text.size > limit
    end

  public
    def owned?(member)
      self.member_id == member.id
    end

    def modified_text
      text = self.text.dup
      text.gsub!(%r{https?://[\w/:%#\$&\?\(\)~\.=\+\-]+}) do |href|
        "<a href=\"#{href}\">#{href}</a>"
      end
      text.gsub(/(\r\n?)|(\n)/, "<br />").html_safe
    end
end
