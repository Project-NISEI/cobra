# frozen_string_literal: true

module UrlHelper
  def tournament_url(slug, request)
    server = "#{request.protocol}#{request.host}"
    server += ":#{request.port}" if !request.port.nil? && (request.port != 80) && (request.port != 443)
    "#{server}/#{slug.downcase}"
  end

  def qr_code(slug, request)
    return unless slug

    @qr_code ||= RQRCode::QRCode.new(
      tournament_url(slug, request),
      size: 4,
      level: :h
    )
  end
end
