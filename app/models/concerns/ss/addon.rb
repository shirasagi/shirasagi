module SS::Addon
  def self.extended(mod)
    mod.extend SS::Translation
  end

  public
    def addon_name
      SS::Addon::Name.new(self)
    end
end
