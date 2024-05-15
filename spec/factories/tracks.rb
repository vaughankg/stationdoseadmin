FactoryGirl.define do
  factory :track do
    station
    spotify_id { Faker::Bitcoin.address }
    echo_nest_song_id { Faker::Bitcoin.address }
    title { Faker::Book.title }
    artist { Faker::Book.author }
    undergroundness { [nil, 1, 2, 3, 4, 5].sample }
    energy { rand }
    valence { rand }
  end
end
