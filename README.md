HasArrayOf
==========

[![Build Status](https://travis-ci.org/marshall-lee/has_array_of.svg)](https://travis-ci.org/marshall-lee/has_array_of)
[![Dependency Status](https://gemnasium.com/marshall-lee/has_array_of.svg)](https://gemnasium.com/marshall-lee/has_array_of)

This plugin implements alternative way to do `has_and_belongs_to_many` association in Rails using the power of PostgreSQL arrays. In many cases when you just need [acts_as_list](https://github.com/swanandp/acts_as_list) or [acts-as-taggable-on](https://github.com/mbleigh/acts-as-taggable-on) functionality the traditional approach using many-to-many with join tables is unnecessary. We can just store integer array of ids.

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
class Playlist < ActiveRecord::Base
  has_array_of :videos  # by convention, it assumes that Post has a video_ids array field
end

# app/models/video.rb
class Video < ActiveRecord::Base
  belongs_to_array_in_many :playlists # optional
end
```

Now we can work with `videos` like with regular array. It will correctly proxy all changes to `video_ids` field.

```ruby
playlist = Playlist.find(1)
playlist.videos = [video1,video2]  # playlist.video_ids = [1, 2]
playlist.videos[0] = video3        # playlist.video_ids[0] = 3
playlist.videos.insert(1, video4)  # playlist.video_ids = [3, 4, 2]
playlist.videos.delete_at(1)       # playlist.video_ids = [3, 2]
playlist.videos.pop                # playlist.video_ids = [3]
# ... and so on

video3.playlists
# => [playlist]
```

`has_array_of` also adds some search scopes:

```ruby
Playlist.with_videos_containing(video1, video2)
Playlist.with_videos_contained_in(video1, video2, video3, video4, ...)
Playlist.with_any_videos_from(video1, video2, video3, video4, ...)
```

Anything like associated lists or arrays can be implemented such way. Now, the more typical example:

```ruby
class Tag; end

class Post
  has_array_of :tags
end
```

Tags, arrays, lists — they're all the same!

# Contribute?

1. Fork it
2. `% bundle install`
3. `% createdb has_array_of_test`
4. `% bundle exec rspec`
5. ...
6. Make pull request!
