class PlaylistTrackGenerator
  def self.call(tracks: [], playlist_profile:)
    # Start with a clean array of possible track contenders
    # Give each track a weight based on the playlist profile
    track_weights_with_index = make_track_weights(tracks, playlist_profile)
    # Select 30 tracks based on their weight
    select_tracks(30, tracks, track_weights_with_index)
  end

  # Give each track a weight based on the playlist profile
  def self.make_track_weights(tracks, playlist_profile)
    track_weights_with_index = tracks.each_with_index.map do |track, index|
      {
        weight: compute_track_weight(track: track, playlist_profile: playlist_profile),
        index: index
      }
    end
    # Sort the array so that the best fitting track is at the top
    track_weights_with_index.sort! do |x, y|
      x[:weight] <=> y[:weight]
    end
  end

  def self.select_tracks(num, tracks, track_weights_with_index, selected_tracks = [])
    return selected_tracks if num.zero?

    selected_tracks << select_track(tracks, track_weights_with_index)

    select_tracks(num - 1, tracks, track_weights_with_index, selected_tracks)
  end

  def self.select_track(tracks, track_weights_with_index)
    # Take the top one
    track_weight_with_index = track_weights_with_index.pop
    track = tracks[track_weight_with_index[:index]]
    # Adjust weights if needed
    adjust_weights_after_selecting(track, tracks, track_weights_with_index)
    # return the track
    track
  end

  # Remove tracks by the same artist
  def self.adjust_weights_after_selecting(track, tracks, track_weights_with_index)
    track_weights_with_index.delete_if do |track_weight_with_index|
      tracks[track_weight_with_index[:index]].artist == track.artist
    end
  end

  #############
  # Computing a tracks weight
  #############

  def self.compute_track_weight(track:, playlist_profile:)
    if track_should_be_rejected?(track: track, playlist_profile: playlist_profile)
      return 0
    end

    criteria_scores = playlist_profile.criteria.values.map do |criteria|
      compute_criteria_weight(criteria: criteria, track: track)
    end

    combine_scores(
      values: criteria_scores,
      factors: playlist_profile.criteria.values.map(&:multiplier)
    )
  end

  # Reject the track is if it busts any criteria min or max requirements
  def self.track_should_be_rejected?(track:, playlist_profile:)
    playlist_profile.criteria.values.any? do |criteria|
      value = track.send(criteria.name)
      value.nil? || value < criteria.min || value > criteria.max
    end
  end

  def self.compute_criteria_weight(criteria:, track:) # rubocop:disable Metrics/MethodLength
    # If there is no target, consider track a perfect match
    return 1 unless criteria.target

    track_value = track.send(criteria.name)

    # If the track is missing a value for the criteria, no bother,
    # we give it a 0 weight
    return 0 unless track_value

    # If the track value is out of bounds, it gets a 0 weight
    return 0 if track_value < criteria.min || track_value > criteria.max

    # Scored from 0-1 based on how close it is to its target
    score = normalized_score(
      value: track.send(criteria.name),
      target: criteria.target,
      global_min: criteria.criteria_min,
      global_max: criteria.criteria_max
    )

    # randomness is build in on the level of criteria
    random_calibrated_score(
      value: score,
      randomness: criteria.randomness
    )
  end

  # normalized_score
  #
  # A value from 0 - 1 indicating how close the value is to the target.
  # In a range 0 to 20, and a target of 10. A value of 10 would yield a
  # normalized weight of 1.0. A value of 0 would yield a value of 0.5.
  # Given a target of 20, a value of 0 would yield a normalaized_weight of 0.0.
  #
  def self.normalized_score(value:, target:, global_min:, global_max:)
    target ? 1 - ((target - value).abs / (global_max - global_min).to_f) : 0
  end

  # combine_scores
  #
  # A value of 0 - 1 obtained by from combining 0 - 1 values and associated
  # weights/factors.Factors should have a sum total of 1.0, this is not strictly
  # enforced and they will be normalized anyway.
  # combine_weights([value1, value2], [factor1, factor2])
  #
  def self.combine_scores(values:, factors:)
    if values.any? { |value| value < 0 || value > 1 }
      raise(ArgumentError, 'value must be [0,1]')
    end

    total_of_factors = factors.reduce(&:+).to_f

    normalized_factors = factors.map { |factor| factor / total_of_factors }

    values.each_with_index.reduce(0) do |memo, (value, i)|
      memo += value * normalized_factors[i]
      memo
    end
  end

  # A value of 0 - 1 obtained by adding a random element to weight from 0-1.
  # @randomness [0-1] is the proportion of the score that is randomised
  def self.random_calibrated_score(value:, randomness:, random_number: rand)
    value * (1 - randomness) + random_number * randomness
  end
end
