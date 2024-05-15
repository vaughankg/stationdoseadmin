# profile_name
# undergroundness
# tracks, array
# summary, hash
# station_id, belongs_to

class Playlist < ApplicationRecord
  belongs_to :station
  serialize :tracks, Array
  serialize :summary, Hash

  def self.generate(playlist_profile, station, options = {})
    all_tracks =
      station
      .tracks
      .where.not(energy: nil)
      .where.not(undergroundness: nil)
      .where.not(valence: nil)

    playlist_tracks = PlaylistTrackGenerator.call(
      tracks: all_tracks,
      playlist_profile: playlist_profile
    )

    Playlist.create(
      station: station,
      summary: playlist_profile.attributes,
      tracks: playlist_tracks
    )
  end

  def tracks_with_user_info(user_id)
    Track.decorate_with_user_info(user_id, station.id, tracks)
  end
end
