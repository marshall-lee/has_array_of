
RSpec.describe HasArrayOf::AssociatedArray do
  include_context "Video model"
  include_context "Playlist model"
  include_context "TV series"

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

  describe "`containing` scope" do
    it "should respond to scope method" do
      expect(Playlist).to respond_to(:with_videos_containing)
    end

    it "should fetch correct results" do
      expect(Playlist.with_videos_containing(something_big))
                              .to contain_exactly(adventure_time_season6,
                                                  my_cool_list)

      expect(Playlist.with_videos_containing(return_of_harmony))
                              .to contain_exactly(mlp_season2,
                                                  my_cool_list)

      expect(Playlist.with_videos_containing(something_big, escape_from_the_citadel))
                              .to contain_exactly(adventure_time_season6)

      expect(Playlist.with_videos_containing(food_chain)).to eq([])
    end

    describe "when passing relation as an argument" do
      it "should fetch correct results" do
        relation = Video.where("title like ? or title like ?", '%Citadel%', '%Something%')
        expect(Playlist.with_videos_containing(relation)).to contain_exactly(adventure_time_season6)
      end
    end

    describe "when passing empty array" do
      it "should fetch all entries" do
        expect(Playlist.with_videos_containing([])).to contain_exactly(*Playlist.all)
      end
    end
  end

  describe "`contained in` scope" do
    it "should respond to scope method" do
      expect(Playlist).to respond_to(:with_videos_contained_in)
    end

    it "should fetch correct results" do
      expect(Playlist.with_videos_contained_in(something_big, return_of_harmony, escape_from_the_citadel))
                              .to contain_exactly(adventure_time_season6,
                                                  mlp_season2,
                                                  my_cool_list)

      expect(Playlist.with_videos_contained_in(food_chain, return_of_harmony))
                              .to contain_exactly(mlp_season2)

      expect(Playlist.with_videos_contained_in(return_of_harmony, something_big, food_chain))
                              .to contain_exactly(mlp_season2,
                                                  my_cool_list)

      expect(Playlist.with_videos_contained_in(food_chain)).to eq([])
    end
  end

  describe "`with any from` scope" do
    it "should respond to scope method" do
      expect(Playlist).to respond_to(:with_any_video_from)
    end

    it "should fetch correct results" do
      expect(Playlist.with_any_video_from(return_of_harmony)).to contain_exactly(my_cool_list,
                                                                                 mlp_season2)

      expect(Playlist.with_any_video_from(something_big)).to contain_exactly(my_cool_list,
                                                                             adventure_time_season6)

      expect(Playlist.with_any_video_from(food_chain)).to eq([])
    end
  end
end
