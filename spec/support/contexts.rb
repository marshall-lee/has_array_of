RSpec.shared_context "Video model" do
  with_model :Video do
    table do |t|
      t.text :title
    end
  end
end

RSpec.shared_context "Playlist model" do
  with_model :Playlist do
    table do |t|
      t.integer :video_ids, array: true, default: []
    end

    model do
      has_array_of :videos
    end
  end

  with_model :AlphaPlaylist do
    table do |t|
      t.integer :video_ids, array: true, default: []
    end

    model do
      has_array_of :videos, order_by: :title
    end
  end

  with_model :TitleLengthPlaylist do
    table do |t|
      t.integer :video_ids, array: true, default: []
    end

    model do
      has_array_of :videos, sort_by: ->(item){item.title.size}
    end
  end
end

RSpec.shared_context "Video model belonging to Playlist" do
  with_model :Video do
    table do |t|
      t.text :title
    end

    model do
      belongs_to_array_in_many :playlists
    end
  end
end

RSpec.shared_context "TV series" do
  let!(:return_of_harmony) {
    Video.create(title: "My Little Pony s02e01 'The Return of Harmony'") # id=1
  }
  let!(:something_big) {
    Video.create(title: "Adventure Time s06e10 'Something Big'") # id=2
  }
  let!(:escape_from_the_citadel) {
    Video.create(title: "Adventure Time s06e02 'Escape from the Citadel'")
  }
  let!(:food_chain) {
    Video.create(title: "Adventure Time s06e07 'Food Chain'")
  }

  let!(:adventure_time_videos) { [something_big, escape_from_the_citadel] }
  let!(:adventure_time_season6) {
    Playlist.create(video_ids: adventure_time_videos.map(&:id))
  }

  let!(:mlp_videos) { [return_of_harmony] }
  let!(:mlp_season2) {
    Playlist.create(video_ids: mlp_videos.map(&:id))
  }

  let!(:my_cool_videos) {
    [return_of_harmony, something_big]
  }
  let!(:my_cool_video_ids) { my_cool_videos.map(&:id) }
  let!(:my_cool_list) {
    Playlist.create(video_ids: my_cool_video_ids.dup)
  }

  let!(:my_alpha_list){
    AlphaPlaylist.create(video_ids: adventure_time_videos.pluck(:id) + [100])
  }

  let!(:my_title_length_list){
    TitleLengthPlaylist.create(video_ids: adventure_time_videos.reverse.pluck(:id) + [100])
  }
end
