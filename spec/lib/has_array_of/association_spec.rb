require 'spec_helper'

RSpec.describe HasArrayOf::Association do
  describe ActiveRecord::Base do
    subject { described_class }
    it { should respond_to(:has_array_of) }
    it { should respond_to(:belongs_to_array_in_many) }
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

    let!(:return_of_harmony) {
      Video.create(title: "My Little Pony s02e01 'The Return of Harmony'")
    }
    let!(:something_big) {
      Video.create(title: "Adventure Time s06e10 'Something Big'")
    }
    let!(:escape_from_the_citadel) {
      Video.create(title: "Adventure Time s06e02 'Escape from the Citadel'")
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
    let!(:my_cool_list) {
      Playlist.create(video_ids: my_cool_videos.map(&:id))
    }

    describe "associated collection reader" do
      it "should respond to scope method" do
        expect(my_cool_list).to respond_to(:videos)
      end

      it "should fetch correct objects" do
        expect(Video.count).to eq(3)
        expect(adventure_time_season6.videos).to contain_exactly(*adventure_time_videos)
        expect(mlp_season2.videos).to contain_exactly(*mlp_videos)
      end
    end

    describe "associated collection assigner" do
      it "should respond to assignment method" do
        expect(my_cool_list).to respond_to(:videos=)
      end

      it "should reflect changes" do
        mlp_season2.videos = adventure_time_videos
        expect(mlp_season2.videos).to eq(adventure_time_videos)
      end

      it "should affect ids" do
        mlp_season2.videos = adventure_time_videos
        expected_ids = adventure_time_videos.map(&:id)
        expect(mlp_season2.video_ids).to eq(expected_ids)
      end
    end

    describe "associated collection appender" do
      let(:expected_videos) { [*my_cool_videos, escape_from_the_citadel] }
      let(:expected_video_ids) { expected_videos.map(&:id) }

      it "should respond to append method" do
        expect(my_cool_list.videos).to respond_to(:<<)
      end

      it "should reflect changes" do
        videos = my_cool_list.videos
        videos << escape_from_the_citadel
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        videos = my_cool_list.videos.load
        videos << escape_from_the_citadel
        expect(videos).to eq(expected_videos)
      end

      it "should modify to_sql" do
        videos = my_cool_list.videos
        expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
        videos << escape_from_the_citadel
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
      end

      it "should affect ids" do
        my_cool_list.videos << escape_from_the_citadel
        expect(my_cool_list.video_ids).to eq(expected_video_ids)
      end

      it "should reset loaded state" do
        videos = my_cool_list.videos.load
        expect(videos).to be_loaded
        videos << escape_from_the_citadel
        expect(videos).not_to be_loaded
      end

      describe "chaining with other queries" do
        it "should work well with queries referencing fields other than primary_key" do
          videos = my_cool_list.videos.where("title like 'Adventure%'")
          expect {
            videos << escape_from_the_citadel
          }.to change(videos, :count).by(1)
        end

        it "should work well with queries referencing primary_key" do
          videos = adventure_time_season6.videos.where(id: mlp_videos.map(&:id))
          expect {
            videos << return_of_harmony
          }.to change(videos, :count).by(1)
        end
      end
    end

    describe "associated collection array element assigner" do
      it "should respond to []=" do
        expect(my_cool_list.videos).to respond_to(:[]=)
      end

      describe "when access by integer index" do
        let(:expected_videos) { [escape_from_the_citadel, something_big] }
        let(:expected_video_ids) { expected_videos.map(&:id) }

        it "should reflect changes" do
          videos = my_cool_list.videos
          videos[0] = escape_from_the_citadel
          expect(videos).to eq(expected_videos)
        end

        it "should reflect changes when loaded" do
          videos = my_cool_list.videos.load
          videos[0] = escape_from_the_citadel
          expect(videos).to eq(expected_videos)
        end

        it "should affect ids" do
          my_cool_list.videos[0] = escape_from_the_citadel
          expect(my_cool_list.video_ids).to eq(expected_video_ids)
        end

        it "should modify to_sql" do
          videos = my_cool_list.videos
          expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
          videos[0] = escape_from_the_citadel
          expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
        end

        it "should affect ids" do
          my_cool_list.videos[0] = escape_from_the_citadel
          expect(my_cool_list.video_ids).to eq(expected_video_ids)
        end

        it "should reset loaded state" do
          videos = my_cool_list.videos.load
          expect(videos).to be_loaded
          videos[0] = escape_from_the_citadel
          expect(videos).not_to be_loaded
        end
      end
    end
  end

  describe "belongs_to_array_in_many scope" do
    pending "TODO"
  end
end
