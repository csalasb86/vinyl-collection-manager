class Track < ApplicationRecord
  belongs_to :album

  validates :title, presence: true
  validates :position, presence: true

  default_scope { order(position_index: :asc) }
end
