module Nrdb
  class Oauth
    def self.auth_uri(host)
      URI("https://netrunnerdb.com/oauth/v2/auth").tap do |uri|
        uri.query = {
          client_id: Rails.configuration.nrdb[:client_id],
          redirect_uri: Rails.configuration.nrdb[:redirect_uri],
          response_type: :code
        }.to_query
      end.to_s
    end

    def self.get_access_token(grant_code)
      JSON.parse(
        Faraday.get(grant_token_uri(grant_code)).body
      ).with_indifferent_access
    end

    def self.grant_token_uri(code)
      URI("https://netrunnerdb.com/oauth/v2/token").tap do |uri|
        uri.query = {
          client_id: Rails.configuration.nrdb[:client_id],
          client_secret: Rails.configuration.nrdb[:client_secret],
          redirect_uri: Rails.configuration.nrdb[:redirect_uri],
          grant_type: :authorization_code,
          code: code
        }.to_query
      end.to_s
    end
    private_class_method :grant_token_uri
  end
end
