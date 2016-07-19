module Member::Addon::Registration
  module RequiredFields
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kana_required, type: String, default: "optional"
      field :organization_name_required, type: String, default: "optional"
      field :job_required, type: String, default: "optional"
      field :tel_required, type: String, default: "optional"
      field :birthday_required, type: String, default: "optional"
      field :sex_required, type: String, default: "optional"
      field :postal_code_required, type: String, default: "optional"
      field :addr_required, type: String, default: "optional"
      validates :kana_required, inclusion: { in: %w(optional required), allow_blank: true }
      validates :organization_name_required, inclusion: { in: %w(optional required), allow_blank: true }
      validates :job_required, inclusion: { in: %w(optional required), allow_blank: true }
      validates :tel_required, inclusion: { in: %w(optional required), allow_blank: true }
      validates :birthday_required, inclusion: { in: %w(optional required), allow_blank: true }
      validates :sex_required, inclusion: { in: %w(optional required), allow_blank: true }
      validates :postal_code_required, inclusion: { in: %w(optional required), allow_blank: true }
      validates :addr_required, inclusion: { in: %w(optional required), allow_blank: true }
      permit_params :kana_required, :organization_name_required, :job_required, :tel_required
      permit_params :birthday_required, :sex_required, :postal_code_required, :addr_required
    end

    def kana_required_options
      %w(optional required).map do |v|
        [ I18n.t("inquiry.options.required.#{v}"), v ]
      end
    end
    alias organization_name_required_options kana_required_options
    alias job_required_options kana_required_options
    alias tel_required_options kana_required_options
    alias birthday_required_options kana_required_options
    alias sex_required_options kana_required_options
    alias postal_code_required_options kana_required_options
    alias addr_required_options kana_required_options

    def kana_required?
      kana_required == 'required'
    end

    def organization_name_required?
      organization_name_required == 'required'
    end

    def job_required?
      job_required == 'required'
    end

    def tel_required?
      tel_required == 'required'
    end

    def birthday_required?
      birthday_required == 'required'
    end

    def sex_required?
      sex_required == 'required'
    end

    def postal_code_required?
      postal_code_required == 'required'
    end

    def addr_required?
      addr_required == 'required'
    end
  end
end
