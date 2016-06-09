module Member::Addon
  module AdditionalAttributes
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :kana, type: String
      field :organization_name, type: String
      field :job, type: String
      field :tel, type: String
      field :postal_code, type: String
      field :addr, type: String
      field :sex, type: String
      field :birthday, type: Date

      attr_accessor :in_birth

      permit_params :kana, :organization_name, :job, :tel, :postal_code, :addr, :sex, :birthday
      permit_params in_birth: [:era, :year, :month, :day]

      before_validation :normalize_postal_code
      before_validation :normalize_in_birth

      validates :kana, length: { maximum: 40 }
      validates :organization_name, length: { maximum: 40 }
      validates :job, length: { maximum: 40 }
      validates :tel, length: { maximum: 40 }
      validates :postal_code, length: { maximum: 40 }
      validates :addr, length: { maximum: 80 }
      validates :sex, inclusion: { in: %w(male female), allow_blank: true }
      validates_with Member::BirthValidator, attributes: :in_birth, if: ->{ in_birth.present? }

      before_save :set_birthday, if: ->{ in_birth.present? }
    end

    def sex_options
      %w(male female).map { |m| [ I18n.t("member.options.sex.#{m}"), m ] }.to_a
    end

    def wareki_options
       I18n.t("views.options.wareki").map { |k, v| [v, k] }
    end

    def parse_in_birth
      if in_birth
        era   = in_birth["era"]
        year  = in_birth["year"]
        month = in_birth["month"]
        day   = in_birth["day"]
      else
        era   = birthday ? "seireki" : nil
        year  = birthday.try(:year)
        month = birthday.try(:month)
        day   = birthday.try(:day)
      end

      [era, year, month, day]
    end

    def age(now = Time.zone.now)
      return nil if birthday.blank?
      return nil if now < birthday
      (now.strftime('%Y%m%d').to_i - birthday.strftime('%Y%m%d').to_i) / 10_000
    end

    private
      def normalize_postal_code
        return if postal_code.blank?
        self.postal_code = postal_code.tr('０-９ａ-ｚＡ-Ｚー－～', '0-9a-zA-Z---')
      end

      def normalize_in_birth
        return if in_birth.blank?
        self.in_birth = in_birth.select { |_, value| value.present? }
      end

      def set_birthday
        era = in_birth[:era]
        year = in_birth[:year].to_i
        month = in_birth[:month].to_i
        day = in_birth[:day].to_i

        wareki = I18n.t("ss.wareki")[era.to_sym]
        return nil if wareki.blank?
        min = Date.parse(wareki[:min])

        self.birthday = Date.new(min.year + year - 1, month, day)
      end
  end
end
