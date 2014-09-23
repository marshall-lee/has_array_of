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

    before do
      # create another videos
      Video.create(title: "my little pony season 01 episode 01")
      Video.create(title: "my little pony season 01 episode 02")
    end
    let(:playlist_videos) {
      [ Video.create(title: "crazy show about unicorns episode 1"),
        Video.create(title: "crazy show about unicorns episode 2") ]
    }

    let!(:playlist) {
      Playlist.create(video_ids: playlist_videos.map(&:id))
    }

    it "should respond to scope method" do
      expect(playlist).to respond_to(:videos)
    end

    it "should fetch correct videos" do
      expect(Video.count).to eq(4)
      expect(playlist.videos).to contain_exactly(*playlist_videos)
    end
  end
end
