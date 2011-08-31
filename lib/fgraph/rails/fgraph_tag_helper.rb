module FGraph
  module Rails
    module FGraphTagHelper
      def fgraph_javascript_include_tag
        %{<script src="http://connect.facebook.net/en_US/all.js"></script>}
      end
      
      # Inititalize XFBML Javascript include and initialization script.
      #
      # ==== Options
      # * <tt>async</tt> - asynchronous javascript include & initialization.
      #   for other Facebook JS initialization codes please wrap under:
      # * <tt>appId</tt> - overrride Fgraph.config['app_id'] value.
      # * <tt>status</tt> - default: true, will check login status, and auto-login user if they are connected
      # * <tt>cookie</tt> - default: true, auto set cookies
      # * <tt>xfbml</tt> - default: true, auto parse xfbml tags
      # * <tt>oauth</tt> - default: true, use Oauth2
      # * <tt>debug</tt> - default: false, use debug JS source from Facebook if true
      # * <tt>channelUrl</tt> - default: 'http://' + location.host + '/fb_channel.htm' - set to false to disable or set it to a full path to change the default
      # Other options will be added to the init call.  See the FB docs for more options:
      # http://developers.facebook.com/docs/reference/javascript/FB.init/
      # 
      # If async is set to true, the callback function is window.afterFbAsyncInit, e.g.
      #   window.afterFbAsyncInit = function() {
      #       ....
      #   }
      #
      def fgraph_javascript_init_tag(options={})
        async = options.delete(:async)
        channelUrl = options.delete(:channelUrl)
        src = options.delete(:debug) ? 'static.ak.fbcdn.net/connect/en_US/core.debug.js' : 'connect.facebook.net/en_US/all.js'
        options = { :appId => FGraph.config['app_id'], 
          :status => true,
          :cookie => true,
          :oauth => true,
          :xfbml => true
        }.merge(options || {})
        
        if channelUrl
          channelUrlstring = channelUrl
        elsif channelUrl == false
          channelUrlstring = ''
        else # default if not specified
          channelUrlstring = ", channelUrl: 'http://' + location.host + '/fb_channel.htm'"
        end
        # chop off the trailing '}', add in the channelUrlstring and close it with out own '}'
        fb_init = "FB.init(#{options.to_json[0..-2]}#{channelUrlstring}});"
        
        if async
          %{
            <div id="fb-root"></div>
            <script>
             try {
              window.fbAsyncInit = function() {
                #{fb_init}
                
                if (window.afterFbAsyncInit) {
                  window.afterFbAsyncInit();
                }
              };
              (function() {
                var e = document.createElement('script'); e.async = true;
                e.src = document.location.protocol +
                  '//#{src}';
                document.getElementById('fb-root').appendChild(e);
              }());
             } catch(e) {
               if(u && u.log_error){u.log_error(e.name, 'FB.init - ' + e.message);}
               alert("Oops, this browser is having trouble connecting to Facebook, please try using a different browser.");
             }
            </script>
          }
        else
          tag = fgraph_javascript_include_tag
          tag << %{
            <div id="fb-root"></div>
            <script>
              #{fb_init}
            </script>
          }
        end
      end

      def fgraph_image_tag(id, type=nil, options={})
        default_options = fgraph_image_options(type)
        default_options[:alt] = id['name'] if id.is_a?(Hash)
        image_tag(fgraph_picture_url(id, type), default_options.merge(options || {}))
      end
      
      def fgraph_image_options(type)
        case type
          when 'square'
            {:width => 50, :height => 50}
          when 'small'
            {:width => 50}
          when 'normal'
            {:width => 100}
          when 'large'
            {:width => 200}
          else
            {:width => 50, :height => 50}
        end
      end
    end 
  end
end