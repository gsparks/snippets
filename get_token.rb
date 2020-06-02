#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'net/http'
require 'uri'
require 'json'

# This task gets a new oauth2 access token
class ServiceNowGetToken < TaskHelper
  def task(user: nil,
           password: nil,
           instance: nil,
           client_secret: nil,
           client_id: nil,
           _target: nil,
           **_kwargs)

    # grant_type password issues a new access and refresh token.
    form_data = { 'client_id' => client_id,
                  'client_secret' => client_secret,
                  'grant_type' => 'password',
                  'username' => user,
                  'password' => password }

    uri = URI.parse("https://#{instance}.service-now.com/oauth_token.do")
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(form_data)
    req_options = {
      use_ssl: uri.scheme == 'https',
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    parsed_reponse = JSON.parse(response.body)

    if parsed_reponse['error_description'] == 'access_denied'
      raise 'Access Denied, please ensure your client_id, client_secret, user, password, and refresh_token are all valid.'
    end

    parsed_reponse.to_json
  rescue => e
    raise "Error retreiving token, #{e}"
  end
end

if $PROGRAM_NAME == __FILE__
  ServiceNowGetToken.run
end
