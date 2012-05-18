require 'net/http'
require 'singleton'

meta :cloudfiles do
  class CloudInfo
    include Singleton

    def auth_token() auth_info[:auth_token] end
    def storage_url() auth_info[:storage_url] end
    def uri() URI.parse storage_url end
    def auth_info() @_auth_info ||= fetch_auth_info end
    def backup_container
      cloudfiles['backup_container']
    end

    def cloudfiles
      "~/current/config/application.yml".p.yaml['cloudfiles']
    end

    def fetch_auth_info
      Net::HTTP.new('auth.api.rackspacecloud.com', 443).tap {|http|
        http.use_ssl = true
      }.start {|http|
        response = http.get('/v1.0', {'X-Auth-User' => cloudfiles['username'], 'X-Auth-Key' => cloudfiles['api_key']})
        if response.is_a? Net::HTTPSuccess
          {
            :auth_token => response['X-Auth-Token'],
            :storage_url => response['X-Storage-Url'],
          }
        end
      }
    end
  end

  template {
    def cloud_info() CloudInfo.instance end
    def cloud_path() "#{cloud_info.backup_container}/#{backup_path.p.basename}" end

    def get_upload_info
      cloud_connection {|http|
        http.request(
          Net::HTTP::Head.new(
            File.join(cloud_info.uri.path, cloud_path),
            {'X-Auth-Token' => cloud_info.auth_token}
          )
        )
      }.response
    end

    def do_cloud_upload
      cloud_connection {|http|
        File.open(backup_path) {|f|
          log_block "Streaming #{backup_path.p.basename} to cloudfiles" do
            http.request(
              Net::HTTP::Put.new(
                File.join(cloud_info.uri.path, cloud_path),
                {'X-Auth-Token' => cloud_info.auth_token}
              ).tap {|request|
                request.body_stream = f
                request.content_length = f.stat.size
              }
            )
          end
        }
      }
    end
    
    def cloud_connection
      Net::HTTP.new(cloud_info.uri.host, 443).tap {|http|
        http.use_ssl = true
      }.start {|http|
        yield http
      }
    end
  }
end
