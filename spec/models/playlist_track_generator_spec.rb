require 'rails_helper'

class PlaylistProfileAnalysis
  def initialize(tracks, playlist_profile)
    @playlist_profile = playlist_profile
    @tracks = tracks
  end

  def do_analaysis(tracks, playlist_profile)
    tracks.map do |track|
      analyze_track(track, playlist_profile)
    end
  end

  def analyze_track(track, playlist_profile)
    criteria_weights = playlist_profile.criteria.values.map do |criteria|
      PlaylistTrackGenerator.compute_criteria_weight(
        criteria: criteria, track: track
      )
    end

    track_weight = PlaylistTrackGenerator.compute_track_weight(
      track: track, playlist_profile: playlist_profile
    )

    { criteria_weights: criteria_weights,
      track_weight: track_weight }
  end

  def average(criteria_name)
    @tracks.map { |track| track.send(criteria_name) }.reduce(&:+) / @tracks.size
  end

  def average_energy
    average(:energy)
  end

  def average_undergroundness
    average(:undergroundness)
  end

  def average_valence
    average(:valence)
  end
end

describe PlaylistTrackGenerator do
  subject { PlaylistTrackGenerator }

  describe '#call' do
    it 'should generate some tracks' do
      station = FactoryGirl.create :station
      playlist_profile = PlaylistProfile.default

      subject.call(tracks: station.tracks, playlist_profile: playlist_profile)
    end

    it 'when randomness is 0 it should be deterministic' do
      station = FactoryGirl.create :station
      playlist_profile = PlaylistProfile.default

      tracks1 = subject.call(tracks: station.tracks, playlist_profile: playlist_profile)
      tracks2 = subject.call(tracks: station.tracks, playlist_profile: playlist_profile)

      analysis1 = PlaylistProfileAnalysis.new(
        tracks1, playlist_profile
      )
      analysis2 = PlaylistProfileAnalysis.new(
        tracks2, playlist_profile
      )

      expect(analysis1.average_energy).to eq analysis2.average_energy
    end

    it 'increasing a criteria target should raise the average' do
      playlist_profile_low = PlaylistProfile.default
      playlist_profile_low.criteria[:energy].target = 0.5
      playlist_profile_high = PlaylistProfile.default
      playlist_profile_high.criteria[:energy].target = 0.8

      station = FactoryGirl.create :station

      tracks_low = subject.call(
        tracks: station.tracks, playlist_profile: playlist_profile_low
      )

      tracks_high = subject.call(
        tracks: station.tracks, playlist_profile: playlist_profile_high
      )

      analysis_low = PlaylistProfileAnalysis.new(
        tracks_low, playlist_profile_low
      )
      analysis_high = PlaylistProfileAnalysis.new(
        tracks_high, playlist_profile_high
      )

      expect(analysis_low.average_energy).to be < analysis_high.average_energy
    end
  end

  describe '#compute_track_weight' do
    it 'if a track breaks the min or max it scores 0' do
      [:energy, :undergroundness, :valence].each do |criteria_name|
        playlist_profile = PlaylistProfile.default
        playlist_profile.criteria[criteria_name].min =
          playlist_profile.criteria[criteria_name].criteria_max + 0.01
        track = FactoryGirl.create :track

        expect(
          subject.compute_track_weight(
            track: track, playlist_profile: playlist_profile
          )
        ).to eq 0

        playlist_profile.criteria[criteria_name].min =
          playlist_profile.criteria[criteria_name].criteria_min
        playlist_profile.criteria[criteria_name].max =
          playlist_profile.criteria[criteria_name].criteria_min - 0.01

        expect(
          subject.compute_track_weight(
            track: track, playlist_profile: playlist_profile
          )
        ).to eq 0
      end
    end
  end

  describe '#combine_score' do
    it 'should produce a number between 0 and 1' do
      expect(
        subject.combine_scores(values: [0.5, 0.5], factors: [0.5, 0.5])
      ).to eq 0.5
      expect(
        subject.combine_scores(values: [0.0, 1.0], factors: [10, 1])
      ).to be < 0.5
      expect(
        subject.combine_scores(values: [0.0, 1.0], factors: [0.4, 0.6])
      ).to be > 0.5
    end

    it 'should raise an argument error when a value is not 0 - 1' do
      expect do
        subject.combine_scores(values: [2.0, 0.5], factors: [0.5, 0.5])
      end.to raise_error(ArgumentError)
    end
  end

  describe '#normalize_score' do
    it 'should yield 1.0 for an exact hit' do
      expect(
        subject.normalized_score(
          value: 5,
          target: 5,
          global_min: 5,
          global_max: 20
        )
      ).to eq 1.0

      expect(
        subject.normalized_score(
          value: 0.5,
          target: 0.5,
          global_min: 0,
          global_max: 1
        )
      ).to eq 1.0
    end

    it 'should yield 0.0 for a complete miss' do
      expect(
        subject.normalized_score(
          value: 5,
          target: 20,
          global_min: 5,
          global_max: 20
        )
      ).to eq 0.0

      expect(
        subject.normalized_score(
          value: 0,
          target: 1,
          global_min: 0,
          global_max: 1
        )
      ).to eq 0.0
    end
  end

  describe '#random_calibrated_score' do
    it 'is deterministic when radmonness is set to 0' do
      value1 = subject.random_calibrated_score(value: 0.5, randomness: 0)
      value2 = subject.random_calibrated_score(value: 0.5, randomness: 0)
      expect(value1).to eq value2
    end

    it 'is random when randomness us set to non-zero' do
      value1 = subject.random_calibrated_score(value: 0.5, randomness: 0.3)
      value2 = subject.random_calibrated_score(value: 0.5, randomness: 0.3)
      expect(value1).not_to eq value2
    end

    it 'finds the mid point when randomness is 0.5' do
      expect(
        subject.random_calibrated_score(
          value: 0.0,
          randomness: 0.5,
          random_number: 1
        )
      ).to eq 0.5
    end
  end
end
