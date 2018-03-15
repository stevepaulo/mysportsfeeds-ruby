require "mysportsfeeds/api/API_v1_0"
require "mysportsfeeds/api/API_v1_1"
require "mysportsfeeds/api/API_v1_2"

### Main class for all interaction with the MySportsFeeds API
class MySportsFeeds

    # Constructor
    def initialize(version='1.0', verbose=False)
        __verify_version(version)

        @version = version
        @verbose = verbose

        # Instantiate an instance of the appropriate API depending on version
        case @version
        when '1.0'
            @api_instance = Mysportsfeeds::Api::API_v1_0.new(@verbose)
        when '1.1'
            @api_instance = Mysportsfeeds::Api::API_v1_1.new(@verbose)
        when '1.2'
            @api_instance = Mysportsfeeds::Api::API_v1_2.new(@verbose)
        else
            raise Exception.new("Unrecognized version specified.  Supported versions are: '1.0', '1.1', '1.2'")
        end
    end

    # Make sure the version is supported
    def __verify_version(version)
        unless %w{1.0 1.1 1.2}.include?(version)
            raise Exception.new("Unrecognized version specified.  Supported versions are: '1.0', '1.1', '1.2'")
        end
    end

    # Authenticate against the API
    def authenticate(username, password)
        if !@api_instance.supports_basic_auth()
            raise Exception.new("BASIC authentication not supported for version " + @version)
        end

        @api_instance.set_auth_credentials(username, password)
    end

    # Request data (and store it if applicable)
    def msf_get_data(league, season, feed, output_format, *kwargs)
        return @api_instance.get_data(league, season, feed, output_format, kwargs)
    end
end
