class UserStationLink < ApplicationRecord
  belongs_to :user
  belongs_to :station
  belongs_to :playlist

  serialize :track_ids, Array

  validates :undergroundness, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
end
