class PlaylistProfileChooser
  def self.load_playlist_profile_templates
    Dir["#{Rails.root}/config/playlist_profiles/*.yml"]
      .reduce({}) do |memo, file|
      data = YAML.load_file(file).deep_symbolize_keys
      memo[data[:name].to_sym] = data
      memo
    end
  end

  # Hash of playlist profile data
  @playlist_profile_templates = load_playlist_profile_templates

  class << self
    attr_reader :playlist_profile_templates
  end

  SCORE_FOR_FORECASTIO_ICONS = {
    'clear-day' => 8,
    'clear-night' => 6,
    'rain' => 1,
    'snow' => 6,
    'sleet' => 1,
    'wind' => 5,
    'fog' => 3,
    'cloudy' => 6,
    'partly-cloudy-day' => 8,
    'partly-cloudy-night' => 6,
    'partly-cloudy' => 5
  }.freeze

  DAY_TIME_SCORES = [
    # 03:05  5:7   7:9  9:11  11:13 13:17 17:19 19:21 21:23 23:02
    [4,    1,    1,    2,    5,    7,    6,    4,    3,    1], # Sunday
    [1,    1,    1,    2,    2,    3,    4,    5,    2,    1], # Monday
    [1,    1,    1,    2,    2,    3,    4,    5,    2,    1], # Tuesday
    [1,    1,    1,    2,    2,    4,    4,    5,    2,    1], # Wednesday
    [2,    1,    1,    3,    5,    6,    5,    5,    3,    1], # Thursday
    [3,    1,    1,    5,    6,    7,    6,    6,    6,    3], # Friday
    [4,    1,    1,    2,    5,    7,    6,    7,    8,    7], # Saturday
  ].freeze

  TIME_LOWER_BOUND_AND_INDEXES = [
    [0, 8],
    [3, 9],
    [5, 0],
    [7, 1],
    [9, 2],
    [11, 3],
    [13, 4],
    [17, 5],
    [19, 6],
    [21, 7],
    [24, 8]
  ].freeze

  ENERGY_PROFILE_NAMES = [
    :mellow, :chill, :vibes, :lounge, :club, :bangin
  ].freeze

  PLAYLIST_SCORES = {
    mellow: 2.5,
    chill: 3.5,
    vibes: 5.9,
    lounge: 6.9,
    club: 8.4,
    bangin: 10
  }.freeze

  include ActiveModel::SerializerSupport

  extend Forwardable

  def_delegators(
    :@playlist_profile,
    :ll, :forecast, :timezone,
    :weather, :hour,
    :day, :name
  )

  attr_reader :localtime

  # attr_accessor(
  #   :ll, :forecast, :timezone,
  #   :localtime, :weather, :hour,
  #   :day, :name, :playlist_profile
  # )

  attr_reader :playlist_profile

  def all_names
    ENERGY_PROFILE_NAMES
  end

  def initialize(options = {})
    profile_args = options.to_h.slice(:ll, :weather, :hour, :day, :name)

    # Get local weather
    profile_args[:ll] ||= '33.985488,-118.475250' # Venice beach
    forecast = forecast_from_location(profile_args[:ll])

    profile_args[:weather] ||= forecast['currently']['icon']
    profile_args[:timezone] = forecast['timezone']

    localtime = ActiveSupport::TimeZone[profile_args[:timezone]].now

    @localtime = localtime

    profile_args[:localtime] ||= localtime.to_s
    profile_args[:hour] ||= localtime.hour
    profile_args[:day] ||= localtime.wday
    profile_args[:name] ||= choose_name(profile_args)

    template = self.class.playlist_profile_templates[profile_args[:name].to_sym]
    profile_args = template.merge(profile_args)

    if options[:undergroundness]
      profile_args[:criteria][:undergroundness][:target] =
        options[:undergroundness]
    end

    @playlist_profile = PlaylistProfile.new(profile_args)
  end

  def forecast_from_location(ll)
    latlng = ll.split(',').map(&:to_f)
    ForecastIO.forecast(*latlng)
  end

  # Choose a profile name based on the weather and time of day
  def choose_name(profile_args)
    weather = profile_args[:weather]
    day = profile_args[:day]
    hour = profile_args[:hour]

    weather_score = score_for_forecastio_icon(weather)
    day_time_score = score_for_day_index_time_index(
      day, time_index_from_hour(hour)
    )
    total_score = (weather_score + day_time_score) / 2.0

    playlist_name_from_score(total_score)
  end

  private

    def score_for_forecastio_icon(icon_name)
      SCORE_FOR_FORECASTIO_ICONS.fetch(icon_name) { rand(10) + 1 }
    end

    def playlist_name_from_score(score)
      PLAYLIST_SCORES.each do |name, value|
        return name if score <= value
      end
    end

    def score_for_day_index_time_index(day_index, time_index)
      DAY_TIME_SCORES[day_index][time_index]
    end

    def time_index_from_hour(hour)
      TIME_LOWER_BOUND_AND_INDEXES.bsearch { |(lbound, _)| hour <= lbound }.last
    end
end
