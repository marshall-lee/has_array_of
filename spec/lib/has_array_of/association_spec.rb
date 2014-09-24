require 'spec_helper'

RSpec.describe HasArrayOf::Association do
  describe ActiveRecord::Base do
    subject { described_class }
    it { should respond_to(:has_array_of) }
  end

  describe "association scope" do
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
  end
end
