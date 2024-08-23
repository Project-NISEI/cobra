module Nrdb
  class Oauth
    def self.auth_uri(host)
      secrets = Rails.application.secrets[host]
      unless secrets
        raise "Secrets not configured for host: #{host}"
      end

      URI("https://netrunnerdb.com/oauth/v2/auth").tap do |uri|
        uri.query = {
          client_id: secrets[:nrdb][:client_id],
          redirect_uri: secrets[:nrdb][:redirect_uri],
          response_type: :code
        }.to_query
      end.to_s
    end

    def self.get_access_token(grant_code, host)
      JSON.parse(
        Faraday.get(grant_token_uri(grant_code, host)).body
      ).with_indifferent_access
    end

    private

    def self.grant_token_uri(code, host)
      URI("https://netrunnerdb.com/oauth/v2/token").tap do |uri|
        uri.query = {
          client_id: Rails.application.secrets[host][:nrdb][:client_id],
          client_secret: Rails.application.secrets[host][:nrdb][:client_secret],
          redirect_uri: Rails.application.secrets[host][:nrdb][:redirect_uri],
          grant_type: :authorization_code,
          code: code
        }.to_query
      end.to_s
    end

    # def self.refresh_token_uri(token)
    #   URI("https://netrunnerdb.com/oauth/v2/token").tap do |uri|
    #     uri.query = {
    #       client_id: Rails.application.secrets[:nrdb]["client_id"],
    #       client_secret: Rails.application.secrets[:nrdb]["client_secret"],
    #       grant_type: :refresh_token,
    #       refresh_token: token
    #     }.to_query
    #   end.to_s
    # end
  end
end
