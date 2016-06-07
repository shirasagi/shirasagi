module Member::Addon::Blog
  module Genre
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :genres, type: SS::Extensions::Lines
      validate :validate_genres
      permit_params genres: []
    end

    private
      def validate_genres
        lines = SS::Extensions::Lines.new(genres).map(&:strip).select(&:present?).uniq

        if lines.select { |line| line.size > 40 }.present?
          errors.add :genres, :too_long, count: 40
        end
        self.genres = lines.join("\n")
      end
  end
end
