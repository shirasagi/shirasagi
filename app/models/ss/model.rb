module SS::Model
  def self.copy_errors(src, dest, prefix: nil)
    src.errors.full_messages.each do |message|
      message = "#{prefix}#{message}" if prefix
      dest.errors.add :base, message
    end
  end
end
