class Station < ApplicationRecord
  has_many :tracks
  has_many :track_bans
  has_many :track_favorites
  has_many :user_station_links
  has_many :playlists

  validates :name, presence: true

  DEFAULT_STATION_OPTIONS = {
    undergroundness: 3,
    saved_station: false
  }.freeze

  # attach a user_station_link here to delegate playlist options
  attr_accessor :user_station_link

  attr_accessor :playlist

  def self.find_with_user(id, user = nil)
    Station.find(id).decorate_with_user_info(user)
  end

  def self.find_with_user!(id, user = nil)
    Station.find(id).decorate_with_user_info!(user)
  end

  def self.from_params(options, user = nil)
    q = if user
      Station.includes(:user_station_links)
    else
      Station.all
    end

    q = q.where(active: true) unless options[:inactive] == true

    if options[:saved_station] == true && user
      q = q.where(user_station_links: { user: user, saved_station: true })
    end

    q = q.where(station_type: options[:station_type]) if options[:station_type]

    q = q.order(updated_at: :desc)

    q.map { |s| s.decorate_with_user_info(user) }
  end

  def generate_playlist(options = {})
    if %w(featured sponsored).include?(station_type)
      @playlist = Playlist.new(
        station: self,
        profile_name: station_type,
        undergroundness: nil,
        tracks: tracks.order(created_at: :asc).to_a,
        summary: {}
      )
    else
      # tracks.sample(30)

      if options[:undergroundness]
        options[:undergroundness] = options[:undergroundness].to_i
      end
      options[:undergroundness] ||= undergroundness

      # Generate a playlist profile based on options supplied
      playlist_profile =
        PlaylistProfileChooser
        .new(options)
        .playlist_profile

      @playlist = Playlist.generate(playlist_profile, self)

      if @user_station_link
        @user_station_link.playlist = @playlist
        @user_station_link.undergroundness = options[:undergroundness]
        @user_station_link.save
      end

      @playlist
    end
  end

  def decorate_with_user_info(user = nil)
    if user
      @user_station_link =
        user_station_links
        .find_by(user: user)
    end

    self
  end

  def decorate_with_user_info!(user = nil)
    if user
      @user_station_link = user_station_links.where(user: user).first_or_create
    end
    self
  end

  # Delegated methods

  # use a local cache if present, otherwise look at the user_station_link
  def playlist
    return @playlist if @playlist

    return nil unless user_station_link.try(:playlist)

    user_station_link.playlist
  end

  def undergroundness
    if user_station_link
      user_station_link.undergroundness
    else
      DEFAULT_STATION_OPTIONS[:undergroundness]
    end
  end

  def saved_station
    if user_station_link
      user_station_link.saved_station
    else
      DEFAULT_STATION_OPTIONS[:saved_station]
    end
  end

  def tracks_updated_at
    return nil unless playlist
    playlist.created_at
  end

  def playlist_tracks
    return [] unless playlist
    return playlist.tracks unless user_station_link
    playlist.tracks_with_user_info(user_station_link.user.id)
  end
end
