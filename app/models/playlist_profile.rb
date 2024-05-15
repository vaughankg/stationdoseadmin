class PlaylistProfile
  class Criteria
    include Virtus.model

    attribute :name, String
    attribute :randomness, Float, default: 0
    attribute :multiplier, Float, default: 1
    attribute :criteria_min, Float
    attribute :criteria_max, Float
    attribute :min_delta, Float
    attribute :max_delta, Float
    # Default to target + min_delta ... then ... criteria_min
    attribute :min, Float, default: (lambda do |criteria, _|
      if criteria.min_delta && criteria.target
        [criteria.target + criteria.min_delta, criteria.criteria_min].max
      else
        criteria.criteria_min
      end
    end)
    # Default to target + max_delta ... then ... criteria_max
    attribute :max, Float, default: (lambda do |criteria, _|
      if criteria.max_delta && criteria.target
        [criteria.target + criteria.max_delta, criteria.criteria_max].min
      else
        criteria.criteria_max
      end
    end)
    attribute :target, Float
  end
end

class PlaylistProfile
  include Virtus.model
  include ActiveModel::SerializerSupport

  def self.default
    filename = "#{Rails.root}/config/playlist_profiles/default.yml"
    data = YAML.load_file(filename).deep_symbolize_keys
    new(data)
  end

  attribute :name, String
  attribute :criteria, Hash[Symbol => Criteria]

  # used for analytics
  attribute :weather, String
  attribute :localtime, String
  attribute :hour, Integer
  attribute :day, Integer
  attribute :timezone, String
  attribute :ll, String
end
