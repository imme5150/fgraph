require 'base64'
require 'json'
require 'openssl'

# FB cookie auth adapted from https://github.com/ptarjan/signed-request/blob/master/sample.rb

module FGraph
  module Rails
	  module FGraphHelper
	    
	    # Access FGraph.config initialized with values set in <tt>[RAILS_ROOT]/config/fgraph.yml</tt>.
	    def fgraph_config
  		  FGraph.config || {}
  		end

		  # Return Facebook session, default to retrieve session from cookies.
  		def fgraph_session(app_id = fgraph_config['app_id'], 
  		  app_secret = fgraph_config['app_secret'])
  			
  			return @fgraph_session if @fgraph_session
  			@fgraph_session = fgraph_session_cookies(app_id, app_secret)
  		end
		
		  # Return Facebook session cookie
  		def fgraph_session_cookies(app_id = fgraph_config['app_id'], 
  			app_secret = fgraph_config['app_secret'])
			
  			return @fgraph_session_cookies if @fgraph_session_cookies
  			return if @fgraph_session_cookies == false
			
  			 # retrieve session from cookie
  			fbsr_cookie = cookies["fbsr_#{app_id}"]
  			if app_id.blank? or app_secret.blank? or fbsr_cookie.blank?
  				return @fgraph_session_cookies = false
  			end

  			# Parse and validate facebook cookie
  			@fgraph_session_cookies = parse_signed_request(fbsr_cookie, app_secret)
  		end
	
  		def fgraph_access_code
  			fgraph_session && fgraph_session['code']
  		end
  		
  		def fgraph_logged_in?
  		  return true if fgraph_session && fgraph_access_code
  		end
		
		  # Currently logged in facebook user
  		def fgraph_current_user
  		  return @fgraph_current_user if @fgraph_current_user
  		  @fgraph_current_user = fgraph_client.me 
  		end
  		
  		# Alias for fgraph_current_user
  		def fgraph_user
  		  fgraph_current_user
  		end
  		
  		# Return FGraph::Client instance initialized with settings set in <tt>fgraph.yml</tt>.
  		# Looks up <tt>:access_token</tt> from code in cookie as well if Facebook session exists.
  		def fgraph_client
  		  return @fgraph_client if @fgraph_client
  		  return unless fgraph_session && fgraph_session['code']
  		  
  		  fgraph_client = FGraph::Client.new(
  			 :client_id => fgraph_config['app_id'],
  			 :client_secret => fgraph_config['app_secret']
  		  )
  		  # turn the Oauth code from the cookie into an access token
  		  unless @access_token
    			access_token_hash = fgraph_client.oauth_access_token('',fgraph_session['code'])
          return unless access_token_hash && access_token_hash['access_token']
          @access_token = access_token_hash['access_token']
        end
        fgraph_client.update_options({:access_token => @access_token})
        @fgraph_client = fgraph_client
  		end
  		
  		# Return Facebook object picture url: http://graph.facebook.com/[id]/picture
      #
      # ==== Type Options
      # * <tt>square</tt> - 50x50 (default)
      # * <tt>small</tt> - 50 pixels wide, variable height
      # * <tt>normal</tt> - 100 pixels wide, variable height
      # * <tt>large</tt> - 200 pixels wide, variable height
      #
      def fgraph_picture_url(id, type=nil)
        id = FGraph.get_id(id)
        url = "http://graph.facebook.com/#{id}/picture"
        url += "?type=#{type}" if type
        url
      end
      
      private
      def base64_url_decode(encoded_url_string)
        encoded_url_string += '=' * (4 - encoded_url_string.length.modulo(4))
        Base64.decode64(encoded_url_string.gsub('-', '+').gsub('_', '/'))
      end

      def parse_signed_request(signed_request, application_secret) #, max_age = 3600)
        encoded_signature, encoded_json = signed_request.split('.', 2)
        json = JSON.parse(base64_url_decode(encoded_json))
        encryption_algorithm = json['algorithm']

        Rails.logger.error 'Unsupported encryption algorithm.' and return false \
          if encryption_algorithm != 'HMAC-SHA256'

#        Rails.logger.warn 'Signed request too old.' and return false \
#          if json['issued_at'] < Time.now.to_i - max_age

        return false if ENV['RAILS_ENV'] != 'development' && base64_url_decode(encoded_signature) !=
              OpenSSL::HMAC.hexdigest('sha256', application_secret, encoded_json).split.pack('H*')

        return json
      end
    end
  end
end