class AbrUpload
  attr_reader :tournament

  def initialize(tournament, tournament_url)
    @tournament = tournament
    @tournament_url = tournament_url
  end

  def upload!
    JSON.parse(send_data).with_indifferent_access
  end

  def self.upload!(tournament, tournament_url)
    new(tournament, tournament_url).upload!
  end

  private

  def send_data()
    Faraday.new do |conn|
      conn.request :multipart
      conn.adapter :net_http
      conn.request :basic_auth, 'cobra', Rails.application.secrets.abr_auth
    end.post endpoint do |req|
      upload = Faraday::UploadIO.new(StringIO.new(json(@tournament, @tournament_url)), 'text/json')
      req.body = { jsonresults: upload }
    end.body
  end

  def endpoint
    "#{Rails.configuration.abr_host}/api/nrtm"
  end

  def json(tournament, tournament_url)
    NrtmJson.new(@tournament).data(@tournament_url).to_json
  end
end
