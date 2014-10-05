require 'spec_helper'

RSpec.describe HasArrayOf::Association do
  describe ActiveRecord::Base do
    subject { described_class }
    it { should respond_to(:has_array_of) }
    it { should respond_to(:belongs_to_array_in) }
  end

  describe "has_array_of scope" do
    with_model :Video do
      table do |t|
        t.text :title
      end
    end
    with_model :Playlist do
      table do |t|
        t.integer :video_ids, array: true, default: []
      end

      model do
        has_array_of :videos
      end
    end

    let!(:another_videos) {
      [ Video.create(title: "my little pony season 01 episode 01"),
        Video.create(title: "my little pony season 01 episode 02") ]
    }

    let!(:playlist_videos) {
      [ Video.create(title: "crazy show about unicorns episode 1"),
        Video.create(title: "crazy show about unicorns episode 2") ]
    }

    let!(:playlist) {
      Playlist.create(video_ids: playlist_videos.map(&:id))
    }

    describe "associated collection reader" do
      it "should respond to scope method" do
        expect(playlist).to respond_to(:videos)
      end

      it "should fetch correct objects" do
        expect(Video.count).to eq(4)
        expect(playlist.videos).to contain_exactly(*playlist_videos)
      end
    end

    describe "associated collection assigner" do
      it "should respond to assignment method" do
        expect(playlist).to respond_to(:videos=)
      end

      it "should reflect changes" do
        playlist.videos = another_videos
        expect(playlist.videos).to eq(another_videos)
      end

      it "should modify ids" do
        playlist.videos = another_videos
        expected_ids = another_videos.map(&:id)
        expect(playlist.video_ids).to eq(expected_ids)
      end
    end

    describe "associated collection appender" do
      it "should respond to append method" do
        expect(playlist.videos).to respond_to(:<<)
      end

      it "should reflect changes" do
        video = another_videos[0]
        videos = playlist.videos
        videos << video
        expected_videos = [*playlist_videos, video]
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        video = another_videos[0]
        videos = playlist.videos.load
        videos << video
        expected_videos = [*playlist_videos, video]
        expect(videos).to eq(expected_videos)
      end

      it "should modify to_sql" do
        video = another_videos[0]
        videos = playlist.videos
        expect(videos.to_sql).to include("(#{playlist_videos.map(&:id).join(', ')})")
        videos << video
        expected_videos = [*playlist_videos, video]
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
      end

      it "should modify ids" do
        video = another_videos[0]
        playlist.videos << video
        expected_ids = [*playlist_videos, video].map(&:id)
        expect(playlist.video_ids).to eq(expected_ids)
      end

      it "should reset loaded state" do
        video = another_videos[0]
        videos = playlist.videos.load
        expect(videos).to be_loaded
        videos << video
        expect(videos).not_to be_loaded
      end

      describe "chaining with other queries" do
        it "should work well with queries referencing fields other than primary_key" do
          video = another_videos[0]
          videos = playlist.videos.where("title like 'crazy%'")
          videos << video
          expect(videos).to eq(playlist_videos)
        end

        it "should work well with queries referencing primary_key" do
          video = another_videos[0]
          videos = playlist.videos.where(id: another_videos.map(&:id))
          videos << video
          expect(videos).to eq([video])
        end
      end
    end
  end

  describe "belongs_to_array_in association" do
    with_model :Video do
      table do |t|
        t.text :title
      end

      model do
        belongs_to_array_in :playlists
      end
    end

    with_model :Playlist do
      table do |t|
        t.integer :video_ids, array: true, default: []
      end

      model do
        has_array_of :videos
      end
    end

    let(:return_of_harmony) {
      Video.create(title: "My Little Pony s02e01 'The Return of Harmony'")
    }
    let(:something_big) {
      Video.create(title: "Adventure Time s06e10 'Something Big'")
    }
    let!(:adventure_time_season6) {
      Playlist.create(videos: [something_big])
    }
    let!(:my_cool) {
      Playlist.create(videos: [return_of_harmony, something_big])
    }
    let!(:mlp_season2) {
      Playlist.create(videos: [return_of_harmony])
    }

    describe "associated collection reader" do
      it "should respond to association method" do
        expect(return_of_harmony).to respond_to(:playlists)
      end

      it "should fetch correct objects" do
        expect(Video.count).to eq(2)
        expect(something_big.playlists).to contain_exactly(adventure_time_season6,
                                                           my_cool)
        expect(return_of_harmony.playlists).to contain_exactly(mlp_season2,
                                                               my_cool)
      end
    end
  end
end
