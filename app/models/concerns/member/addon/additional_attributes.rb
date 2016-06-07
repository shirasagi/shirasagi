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

      attr_accessor :kana_required, :organization_name_required, :job_required, :tel_required, :postal_code_required
      attr_accessor :addr_required, :sex_required, :birthday_required
      attr_accessor :in_birth

      permit_params :kana, :organization_name, :job, :tel, :postal_code, :addr, :sex, :birthday
      permit_params in_birth: [:era, :year, :month, :day]

      before_validation :normalize_postal_code
      before_validation :normalize_in_birth

      validates :kana, length: { maximum: 40 }
      validates :kana, presence: true, if: ->{ kana_required }
      validates :organization_name, length: { maximum: 40 }
      validates :organization_name, presence: true, if: ->{ organization_name_required }
      validates :job, length: { maximum: 40 }
      validates :job, presence: true, if: ->{ job_required }
      validates :tel, length: { maximum: 40 }
      validates :tel, presence: true, if: ->{ tel_required }
      validates :postal_code, length: { maximum: 40 }
      validates :postal_code, presence: true, if: ->{ postal_code_required }
      validates :addr, length: { maximum: 80 }
      validates :addr, presence: true, if: ->{ addr_required }
      validates :sex, inclusion: { in: %w(male female), allow_blank: true }
      validates :sex, presence: true, if: ->{ sex_required }
      validates_with Member::BirthValidator, attributes: :in_birth, if: ->{ in_birth.present? }
      validates :in_birth, presence: true, if: ->{ birthday_required }

      before_save :set_birthday, if: ->{ in_birth.present? }
    end

    def sex_options
      %w(male female).map { |m| [ I18n.t("member.options.sex.#{m}"), m ] }.to_a
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

        wareki = SS.config.ss.wareki[era]
        return nil if wareki.blank?
        min = Date.parse(wareki['min'])

        self.birthday = Date.new(min.year + year - 1, month, day)
      end
  end
end
