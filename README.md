= HasArrayOf

This plugin implements alternative way to do `has_and_belongs_to_many` association in Rails using a power of PostgreSQL arrays. In simple cases when you just need [acts_as_list](https://github.com/swanandp/acts_as_list) or [acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on) functionality the traditional approach using many-to-many with join tables is unnecessary. We can just store integer array of ids.

# How does it work?

Suppose we have a playlist that contains many videos. One video can be included in many playlists. It's a classic many-to-many situation but we implement it differently.


```ruby
# db/migrate/20141027125227_create_playlist.rb
class CreatePlaylist < ActiveRecord::Migration
  def change
    create_table :playlists do |t|
      t.integer :video_ids, array: true # adding array fields works only starting from Rails 4
      t.index :video_ids, using: :gin   # we add GIN index to speed up specific queries on array
    end
  end
end

# app/models/playlist.rb
class Playlist
  has_array_of :videos  # by convention, it assumes that Post has a video_ids array field
end

# app/models/video.rb
class Video
  belongs_to_array_in_many :playlists # optional
end
```

