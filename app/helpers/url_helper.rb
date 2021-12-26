module UrlHelper
  def tournament_url(slug, request)
    server = "#{request.protocol}#{request.host}"
    if request.port != nil and request.port != 80 and request.port != 443
      server += ":#{request.port}"
    end
    return "#{server}/#{slug.downcase}"
  end

  def qr_code(slug, request)
    @qr ||= RQRCode::QRCode.new(
      tournament_url(slug, request),
      size: 4,
      level: :h
    ) if slug
  end
end
