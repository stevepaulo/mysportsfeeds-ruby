require 'net/http'
require 'uri'
require 'openssl'
require 'json'
require 'fileutils'

require 'mysportsfeeds/version'

module Mysportsfeeds
    module Api
        # API class for dealing with v1.0 of the API
        class API_v1_0

            # Constructor
            def initialize(verbose)
                @base_uri = URI("https://api.mysportsfeeds.com/v1.0/pull")
                @headers = {
                    "Accept-Encoding" => "gzip",
                    "User-Agent" => "MySportsFeeds Ruby/#{Mysportsfeeds::Ruby::VERSION} (#{RUBY_PLATFORM})"
                }

                @verbose = verbose

                @valid_feeds = [
                    'current_season',
                    'cumulative_player_stats',
                    'full_game_schedule',
                    'daily_game_schedule',
                    'daily_player_stats',
                    'game_playbyplay',
                    'game_boxscore',
                    'scoreboard',
                    'player_gamelogs',
                    'team_gamelogs',
                    'roster_players',
                    'game_startinglineup',
                    'active_players',
                    'player_injuries',
                    'latest_updates',
                    'daily_dfs',
                    'overall_team_standings',
                    'conference_team_standings',
                    'division_team_standings',
                    'playoff_team_standings'
                ]
            end

            # Verify a feed
            def __verify_feed_name(feed)
                is_valid = false

                for value in @valid_feeds
                    if value == feed
                        is_valid = true
                        break
                    end
                end

                return is_valid
            end

            # Verify output format
            def __verify_format(format)
                is_valid = true

                if format != 'json' and format != 'xml' and format != 'csv'
                    is_valid = false
                end

                return is_valid
            end

            # Feed URL (with only a league specified)
            def __league_only_url(league, feed, output_format, params)
                url "#{@base_uri.to_s}/#{league}/#{feed}.#{output_format}"

                delim = "?"
                params.each do |key, value|
                    url << delim << key << "=" << value
                    delim = "&"
                end

                return url
            end

            # Feed URL (with league + season specified)
            def __league_and_season_url(league, season, feed, output_format, params)
                url = "#{@base_uri.to_s}/#{league}/#{season}/#{feed}.#{output_format}"

                delim = "?"
                params.each do |key, value|
                    url << delim << key << "=" << value
                    delim = "&"
                end

                return url
            end

            # Indicate this version does support BASIC auth
            def supports_basic_auth()
                return true
            end

            # Establish BASIC auth credentials
            def set_auth_credentials(username, password)
                @auth = {"username" => username, "password" => password}
            end

            # Request data (and store it if applicable)
            def get_data(league, season, feed, output_format, kwargs)
                if !@auth
                    raise Exception.new("You must authenticate() before making requests.")
                end

                # establish defaults for all variables
                params = {}

                # add force=false parameter (helps prevent unnecessary bandwidth use)
                kwargs.each do |kwarg|
                    kwarg.each do |key, value|
                        params[key] = value
                    end
                end

                if !params.key?("force")
                    params['force'] = 'false'
                end

                if __verify_feed_name(feed) == false
                    raise Exception.new("Unknown feed '" + feed + "'.")
                end

                if __verify_format(output_format) == false
                    raise Exception.new("Unsupported format '" + output_format + "'.")
                end

                if feed == 'current_season'
                    url = __league_only_url(league, feed, output_format, params)
                else
                    url = __league_and_season_url(league, season, feed, output_format, params)
                end

                if @verbose
                    puts "Making API request to '#{url}'."
                    puts "  with headers:"
                    puts @headers
                end

                http = Net::HTTP.new(@base_uri.host, @base_uri.port)
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                request = Net::HTTP::Get.new(url)
                request.basic_auth(@auth["username"], @auth["password"])

                r = http.request(request)
                if @verbose
                    puts "response = #{r}"
                end

                if r.code == "200"
                    if output_format == "json"
                        data = JSON.parse(r.body)
                    elsif output_format == "xml"
                        data = r.body
                    else
                        data = r.body
                    end
                elsif r.code == "304"
                    if @verbose
                        puts "Data hasn't changed since last call"
                    end
                else
                    puts "API call failed with error: #{r.code}"
                end

                return data
            end
        end
    end
end
