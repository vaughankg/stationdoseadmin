class Api::V1::SpotifyController < Api::V1::ApiController

  CLIENT_ID = ENV["spotify_client_id"]
  CLIENT_SECRET = ENV["spotify_client_secret"]
  ENCRYPTION_SECRET = ENV["spotify_encryption_secret"]
  CLIENT_CALLBACK_URL = ENV["spotify_client_callback_url"]
  AUTH_HEADER = "Basic " + Base64.strict_encode64(CLIENT_ID + ":" + CLIENT_SECRET)
  SPOTIFY_ACCOUNTS_ENDPOINT = URI.parse("https://accounts.spotify.com")
  SPOTIFY_API_ENDPOINT = URI.parse("https://api.spotify.com")

  def swap

    # This call takes a single POST parameter, "code", which
    # it combines with your client ID, secret and callback
    # URL to get an OAuth token from the Spotify Auth Service,
    # which it will pass back to the caller in a JSON payload.

    auth_code = params[:code]

    http = Net::HTTP.new(SPOTIFY_ACCOUNTS_ENDPOINT.host, SPOTIFY_ACCOUNTS_ENDPOINT.port)
    http.use_ssl = true

    _request = Net::HTTP::Post.new("/api/token")

    _request.add_field("Authorization", AUTH_HEADER)

    _request.form_data = {
      "grant_type" => "authorization_code",
      "redirect_uri" => CLIENT_CALLBACK_URL,
      #"redirect_uri" => "http://localhost:3000/api/spotify/callback",
      "code" => auth_code
    }

    _response = http.request(_request)

    # encrypt the refresh token before forwarding to the client
    if _response.code.to_i == 200
      token_data = JSON.parse(_response.body)
      refresh_token = token_data["refresh_token"]
      encrypted_token = refresh_token.encrypt(:symmetric, :password => ENCRYPTION_SECRET)
      token_data["refresh_token"] = encrypted_token
      _response.body = JSON.dump(token_data)
    end

    render json: _response.body, status: _response.code.to_i
  end

  def refresh

    # Request a new access token using the POST:ed refresh token

    http = Net::HTTP.new(SPOTIFY_ACCOUNTS_ENDPOINT.host, SPOTIFY_ACCOUNTS_ENDPOINT.port)
    http.use_ssl = true

    _request = Net::HTTP::Post.new("/api/token")

    _request.add_field("Authorization", AUTH_HEADER)

    encrypted_token = params[:refresh_token]
    refresh_token = encrypted_token.decrypt(:symmetric, :password => ENCRYPTION_SECRET)

    _request.form_data = {
      "grant_type" => "refresh_token",
      "refresh_token" => refresh_token
    }

    _response = http.request(_request)

    render json: _response.body, status: _response.code.to_i
  end

  # Sign in with omniauth
  def callback
    user = User.from_omniauth(request.env['omniauth.auth'])
    render json: user, meta: request.env['omniauth.auth']
  end

  # Make a request to Spotify's /me endpoint to grab the user id then find or create that user
  #
  # response from https://api.spotify.com/v1/me looks like this:
  # {
  #   "display_name":"JMWizzler",
  #   "email":"email@example.com",
  #   "external_urls":{
  #     "spotify":"https://open.spotify.com/user/wizzler"
  #   },
  #   "href":"https://api.spotify.com/v1/users/wizzler",
  #   "id":"wizzler",
  #   "images":[{
  #     "height":null,
  #     "url":"https://fbcdn...2330_n.jpg",
  #     "width":null
  #   }],
  #   "product":"premium",
  #   "type":"user",
  #   "uri":"spotify:user:wizzler"
  # }
  def create_session
    # find the stationdose user using a spotify access_token and include their id and auth_token
    access_token = params["access_token"]

    http = Net::HTTP.new(SPOTIFY_API_ENDPOINT.host, SPOTIFY_API_ENDPOINT.port)
    http.use_ssl = true

    _request = Net::HTTP::Get.new("/v1/me")
    _request.add_field("Authorization", "Bearer #{access_token}")
    _response = http.request(_request)

    if _response.code.to_i == 200
      data = JSON.parse(_response.body)
      user = User.from_spotify_id(data["id"])
      user.generate_authentication_token!
      user.save

      render json: user, status: 200
    else
      render json: _response.body, status: _response.code.to_i
    end
  end

  def destroy_session
    user = User.find_by(auth_token: params[:id])
    user.generate_authentication_token!
    user.save
    head 204
  end

end
