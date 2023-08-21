class Jmaxml::Renderer::Tornado < Jmaxml::Renderer::Main
  include Jmaxml::Helper::Tornado

  def jmaxml_type
    :tornado
  end
end
