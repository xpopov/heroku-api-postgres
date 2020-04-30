module Heroku
  module Api
    module Postgres
      def self.connect_oauth(oauth_client_key = ENV['HEROKU_OAUTH_TOKEN'], pro_plan = false)
        Client.new(oauth_client_key, pro_plan)
      end

      class Client
        attr_reader :oauth_client_key

        def initialize(oauth_client_key, pro_plan = false)
          @oauth_client_key = oauth_client_key
          @basic_url = pro_plan ? Databases::PRO_HOST : Databases::STARTER_HOST
        end

        def backups
          @backups ||= Backups.new(self)
        end

        def databases
          @databases ||= Databases.new(self)
        end

        def perform_get_request(path, options = {})
          url = build_uri(path, options)
          req = Net::HTTP::Get.new(url)
          add_auth_headers(req)
          response = start_request(req, url)
          parse_response(response)
        end

        def perform_post_request(path, params = {}, options = {})
          url = build_uri(path, options)
          req = Net::HTTP::Post.new(url)
          add_auth_headers(req)
          req.body = params.to_json
          response = start_request(req, url)
          parse_response(response)
        end

        def perform_put_request(path, params = {}, options = {})
          url = build_uri(path, options)
          req = Net::HTTP::Put.new(url)
          add_auth_headers(req)
          req.body = params.to_json
          response = start_request(req, url)
          parse_response(response)
        end

        private

        def build_uri(path, host: @basic_url)
          URI.join(host, path)
        end

        def add_auth_headers(req)
          req['Accept'] = 'application/vnd.heroku+json; version=3'
          req.basic_auth '', @oauth_client_key
        end

        def start_request(req, url)
          http_new = Net::HTTP.new(url.hostname, url.port)
          http_new.use_ssl = true
          http_new.start { |http| http.request(req) }
        end

        def parse_response(response)
          if %w[200 201].include? response.code
            JSON.parse(response.body, symbolize_names: true)
          else
            { error: { status: response.code.to_i } }
          end
        end
      end
    end
  end
end
