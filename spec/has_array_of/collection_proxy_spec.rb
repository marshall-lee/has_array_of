require 'spec_helper'

RSpec.describe HasArrayOf::CollectionProxy do
  include_context "Video model"
  include_context "Playlist model"
  include_context "TV series"

  let!(:two_food_chains_and_pony_videos) {
    [food_chain, return_of_harmony, food_chain]
  }
  let!(:two_food_chains_and_pony_video_ids) {
    two_food_chains_and_pony_videos.map(&:id)
  }
  let!(:two_food_chains_and_pony) {
    Playlist.create(video_ids: two_food_chains_and_pony_video_ids)
  }

  describe "associated collection reader" do
    it "should respond to scope method" do
      expect(my_cool_list).to respond_to(:videos)
    end

    it "should fetch correct objects" do
      expect(Video.count).to eq(4)
      expect(adventure_time_season6.videos).to eq(adventure_time_videos)
      expect(mlp_season2.videos).to eq(mlp_videos)
    end

    it "should correctly deal with dups" do
      expect(two_food_chains_and_pony.videos).to eq(two_food_chains_and_pony_videos)
      expect(two_food_chains_and_pony.videos.map(&:id)).to eq(two_food_chains_and_pony_video_ids)
    end

    it "should correctly deal with nil" do
      playlist = Playlist.create video_ids: [nil, something_big.id, nil]
      expect(playlist.videos).to eq([something_big])
      playlist = Playlist.create video_ids: [nil, nil, nil]
      expect(playlist.videos).to eq([])
    end

    describe "when chaining with other queries" do
      let(:playlist) { two_food_chains_and_pony }

      it "should fetch correct objects" do
        expect(playlist.videos.where("title like '%Pony%'")).to eq([return_of_harmony])
        expect(playlist.videos.where("title like '%Adventure%'")).to eq([food_chain, food_chain])
      end

      describe "when having nils" do
        before do
          playlist.videos << nil
          playlist.save
        end

        it "should fetch correct objects" do
          videos = playlist.videos
          expect(videos.where("title like '%Pony%'")).to eq([return_of_harmony])
          videos.where!("title like '%Adventure%'")
          expect(videos.to_a).to eq([food_chain, food_chain])
        end
      end
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

  describe "method <<" do
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
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos << escape_from_the_citadel
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
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

    it "should correctly append nil values" do
      videos = my_cool_list.videos
      videos << nil
      expect(my_cool_list.video_ids).to eq([*my_cool_video_ids, nil])
    end
  end

  describe "method []=" do
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
        expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
        videos[0] = escape_from_the_citadel
        expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
      end

      it "should reset loaded state" do
        videos = my_cool_list.videos.load
        expect(videos).to be_loaded
        videos[0] = escape_from_the_citadel
        expect(videos).not_to be_loaded
      end

      it "should correctly deal with nil values" do
        videos = my_cool_list.videos
        videos[0] = nil
        expect(my_cool_list.video_ids[0]).to be_nil
      end
    end

    describe "when access with start and length" do
      let!(:harlem_shake) {
        Video.create(title: "The Harlem Shake")
      }
      let!(:gangnam_style) {
        Video.create(title: "Gangnam Style")
      }
      let!(:spider_dog) {
        Video.create(title: "Mutant Giant Spider Dog")
      }
      let!(:chandelier) {
        Video.create(title: "Sia - Chandelier (Official Video)")
      }
      let!(:another_memes) {
        [harlem_shake, gangnam_style, spider_dog, chandelier]
      }
      let!(:another_meme_ids) {
        another_memes.map(&:id)
      }
      let!(:another_playlist) {
        Playlist.create(video_ids: another_meme_ids)
      }
      let(:expected_videos) {
        [harlem_shake, return_of_harmony, something_big, chandelier]
      }
      let(:expected_video_ids) {
        expected_videos.map(&:id)
      }

      it "should reflect changes" do
        videos = another_playlist.videos
        videos[1,2] = [return_of_harmony, something_big]
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        videos = another_playlist.videos.load
        videos[1,2] = [return_of_harmony, something_big]
        expect(videos).to eq(expected_videos)
      end

      it "should affect ids" do
        another_playlist.videos[1,2] = [return_of_harmony, something_big]
        expect(another_playlist.video_ids).to eq(expected_video_ids)
      end

      it "should modify to_sql" do
        videos = another_playlist.videos.load
        expect(videos.to_sql).to include("(#{another_meme_ids.join(', ')})")
        videos[1,2] = [return_of_harmony, something_big]
        expect(videos.to_sql).to include("(#{expected_video_ids.join(', ')})")
      end

      it "should reset loaded state" do
        videos = another_playlist.videos.load
        expect(videos).to be_loaded
        videos[1,2] = [return_of_harmony, something_big]
        expect(videos).not_to be_loaded
      end

      it "should correctly deal with nil values" do
        videos = another_playlist.videos
        videos[1,2] = [nil, nil, nil]
        expect(another_playlist.video_ids).to eq([harlem_shake.id, nil, nil, nil, chandelier.id])
      end
    end
  end

  xdescribe "compact! method" do
    before {
      my_cool_list.videos << nil
      my_cool_list.save
    }
    let(:expected_videos) { [return_of_harmony, something_big] }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to compact! method" do
      expect(my_cool_list.videos).to respond_to(:compact!)
    end

    it "should contain nil" do
      expect(my_cool_list.videos).to include(nil)
      expect(my_cool_list.videos.length).to eq(3)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.compact!
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.compact!
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.compact!
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.compact!
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.compact!).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.compact!
      expect(videos).not_to be_loaded
    end
  end

  describe "concat method" do
    let(:other_videos) { [escape_from_the_citadel, food_chain] }
    let(:expected_videos) { [return_of_harmony, something_big] + other_videos }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to compact! method" do
      expect(my_cool_list.videos).to respond_to(:compact!)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.concat other_videos
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.concat other_videos
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.concat other_videos
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.concat other_videos
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.concat other_videos).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.concat other_videos
      expect(videos).not_to be_loaded
    end
  end

  describe "delete method" do
    let(:expected_videos) { [return_of_harmony] }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to delete method" do
      expect(my_cool_list.videos).to respond_to(:delete)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.delete something_big
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.delete something_big
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.delete something_big
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.delete something_big
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return deleted element" do
      videos = my_cool_list.videos
      expect(videos.delete something_big).to eq(something_big)
    end

    it "should return nil when deleting non-existing element" do
      videos = my_cool_list.videos
      expect(videos.delete escape_from_the_citadel).to be_nil
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.delete something_big
      expect(videos).not_to be_loaded
    end
  end

  describe "delete_at method" do
    let(:expected_videos) { [something_big] }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to delete_at method" do
      expect(my_cool_list.videos).to respond_to(:delete_at)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.delete_at 0
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.delete_at 0
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.delete_at 0
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.delete_at 0
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return deleted element" do
      videos = my_cool_list.videos
      expect(videos.delete_at 0).to eq(return_of_harmony)
    end

    it "should return nil when deleting non-existing element" do
      videos = my_cool_list.videos
      expect(videos.delete_at 2).to be_nil
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.delete_at 0
      expect(videos).not_to be_loaded
    end
  end

  describe "delete_if method" do
    let(:expected_videos) { [return_of_harmony] }
    let(:expected_video_ids) { expected_videos.map(&:id) }
    let(:block) { proc { |video| video.title.include? "Something" } }

    it "should respond to delete_if method" do
      expect(my_cool_list.videos).to respond_to(:delete_if)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.delete_if(&block)
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.delete_if(&block)
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.delete_if(&block)
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.delete_if(&block)
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.delete_if(&block)).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.delete_if(&block)
      expect(videos).not_to be_loaded
    end

    it "should return enumerator when calling without block" do
      expect(my_cool_list.videos.delete_if).to be_a(Enumerator)
      expect(my_cool_list.videos.delete_if.inspect).to include("delete_if")
    end
  end

  describe "fill method" do
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to fill method" do
      expect(my_cool_list.videos).to respond_to(:fill)
    end

    describe "when calling without block" do
      let(:expected_videos) { [food_chain, food_chain] }

      it "should reflect changes" do
        videos = my_cool_list.videos
        videos.fill food_chain
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        videos = my_cool_list.videos.load
        videos.fill food_chain
        expect(videos).to eq(expected_videos)
      end

      it "should modify to_sql" do
        videos = my_cool_list.videos
        expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
        videos.fill food_chain
        expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
      end

      it "should affect ids" do
        my_cool_list.videos.fill food_chain
        expect(my_cool_list.video_ids).to eq(expected_video_ids)
      end

      it "should return self" do
        videos = my_cool_list.videos
        expect(videos.fill food_chain).to eq(videos)
      end

      it "should reset loaded state" do
        videos = my_cool_list.videos.load
        expect(videos).to be_loaded
        videos.fill food_chain
        expect(videos).not_to be_loaded
      end

      describe "and with index and length or with range" do
        before(:each) do
          my_cool_list.videos.concat [escape_from_the_citadel, food_chain]
          my_cool_list.save
        end

        it "should reflect changes" do
          videos = my_cool_list.videos
          videos.fill food_chain, 2, 2
          expect(videos).to eq([return_of_harmony, something_big, food_chain, food_chain])
          videos.fill escape_from_the_citadel, 0..1
          expect(videos).to eq([escape_from_the_citadel, escape_from_the_citadel, food_chain, food_chain])
          videos.fill something_big, 1
          expect(videos).to eq([escape_from_the_citadel, something_big, something_big, something_big])
          expect(videos.length).to eq(4)
        end

        it "should affect ids" do
          videos = my_cool_list.videos
          videos.fill food_chain, 2, 2
          expect(videos.map(&:id)).to eq([return_of_harmony, something_big, food_chain, food_chain].map(&:id))
          videos.fill escape_from_the_citadel, 0..1
          expect(videos.map(&:id)).to eq([escape_from_the_citadel, escape_from_the_citadel, food_chain, food_chain].map(&:id))
          videos.fill something_big, 1
          expect(videos.map(&:id)).to eq([escape_from_the_citadel, something_big, something_big, something_big].map(&:id))
        end
      end
    end

    describe "when calling with block" do
      let(:other_videos) { [escape_from_the_citadel, food_chain] }
      let(:expected_videos) { other_videos }

      it "should reflect changes" do
        videos = my_cool_list.videos
        videos.fill { |i| other_videos[i] }
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        videos = my_cool_list.videos.load
        videos.fill { |i| other_videos[i] }
        expect(videos).to eq(expected_videos)
      end

      it "should modify to_sql" do
        videos = my_cool_list.videos
        expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
        videos.fill { |i| other_videos[i] }
        expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
      end

      it "should affect ids" do
        my_cool_list.videos.fill { |i| other_videos[i] }
        expect(my_cool_list.video_ids).to eq(expected_video_ids)
      end

      it "should return self" do
        videos = my_cool_list.videos
        expect(videos.fill { |i| other_videos[i] }).to eq(videos)
      end

      it "should reset loaded state" do
        videos = my_cool_list.videos.load
        expect(videos).to be_loaded
        videos.fill { |i| other_videos[i] }
        expect(videos).not_to be_loaded
      end

      describe "and with index and length or with range" do
        it "should reflect changes" do
          videos = my_cool_list.videos
          videos.fill(2, 2) { |i| other_videos[i-2] }
          expect(videos).to eq([return_of_harmony, something_big, escape_from_the_citadel, food_chain])
          videos.fill(0..1) { |i| other_videos[i] }
          expect(videos).to eq([escape_from_the_citadel, food_chain, escape_from_the_citadel, food_chain])
        end

        it "should affect ids" do
          videos = my_cool_list.videos
          videos.fill(2, 2) { |i| other_videos[i-2] }
          expect(videos.map(&:id)).to eq([return_of_harmony, something_big, escape_from_the_citadel, food_chain].map(&:id))
          videos.fill(0..1) { |i| other_videos[i] }
          expect(videos.map(&:id)).to eq([escape_from_the_citadel, food_chain, escape_from_the_citadel, food_chain].map(&:id))
        end
      end
    end
  end

  describe "insert method" do
    let(:other_videos) { [escape_from_the_citadel, food_chain] }
    let(:expected_videos) { [return_of_harmony, escape_from_the_citadel, food_chain, something_big] }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to insert method" do
      expect(my_cool_list.videos).to respond_to(:insert)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.insert 1, *other_videos
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.insert 1, *other_videos
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.insert 1, *other_videos
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.insert 1, *other_videos
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.insert 1, *other_videos).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.insert 1, *other_videos
      expect(videos).not_to be_loaded
    end
  end

  describe "keep_if method" do
    let(:expected_videos) { [something_big] }
    let(:expected_video_ids) { expected_videos.map(&:id) }
    let(:block) { proc { |video| video.title.include? "Something" } }

    it "should respond to keep_if method" do
      expect(my_cool_list.videos).to respond_to(:keep_if)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.keep_if(&block)
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.keep_if(&block)
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.keep_if(&block)
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.keep_if(&block)
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.keep_if(&block)).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.keep_if(&block)
      expect(videos).not_to be_loaded
    end

    it "should return enumerator when calling without block" do
      expect(my_cool_list.videos.keep_if).to be_a(Enumerator)
      expect(my_cool_list.videos.keep_if.inspect).to include("keep_if")
    end
  end

  describe "map! method" do
    let(:expected_videos) { my_cool_videos.drop 1 }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to map! method" do
      expect(my_cool_list.videos).to respond_to(:map!)
    end

    # TODO: in progress

    it "should return enumerator when calling without block" do
      expect(my_cool_list.videos.map!).to be_a(Enumerator)
      expect(my_cool_list.videos.map!.inspect).to include("map!")
    end
  end

  describe "pop method" do
    let(:expected_videos) { my_cool_videos.take(my_cool_videos.length-1) }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to pop method" do
      expect(my_cool_list.videos).to respond_to(:pop)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.pop
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.pop
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.pop
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.pop
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return popped element" do
      videos = my_cool_list.videos
      expect(videos.pop).to eq(something_big)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.pop
      expect(videos).not_to be_loaded
    end
  end

  describe "push method" do
    let(:other_videos) { [escape_from_the_citadel, food_chain] }
    let(:expected_videos) { my_cool_videos + other_videos }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to push method" do
      expect(my_cool_list.videos).to respond_to(:push)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.push(*other_videos)
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.push(*other_videos)
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_list.videos.map(&:id))
      videos.push(*other_videos)
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.push(*other_videos)
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.push(*other_videos)).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.push(*other_videos)
      expect(videos).not_to be_loaded
    end
  end

  describe "reject! method" do
    let(:block) { proc { |video| video.title.include? "Something" } }

    it "should respond to reject! method" do
      expect(my_cool_list.videos).to respond_to(:reject!)
    end

    it "should return self if changes are made" do
      expect(my_cool_list.videos.reject!(&block)).to eq(my_cool_list.videos)
    end

    it "should return nil if changes are not made" do
      expect(my_cool_list.videos.reject!{ false }).to be_nil
    end

    it "should return enumerator when calling without block" do
      expect(my_cool_list.videos.reject!).to be_a(Enumerator)
      expect(my_cool_list.videos.reject!.inspect).to include("reject!")
    end
  end

  describe "replace method" do
    let(:other_videos) { [escape_from_the_citadel, food_chain] }
    let(:expected_videos) { other_videos }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to replace method" do
      expect(my_cool_list.videos).to respond_to(:replace)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.replace other_videos
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.replace other_videos
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_list.videos.map(&:id))
      videos.replace other_videos
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.replace other_videos
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.replace other_videos).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.replace other_videos
      expect(videos).not_to be_loaded
    end
  end

  describe "reverse! method" do
    let(:expected_videos) { [something_big, return_of_harmony] }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to reverse! method" do
      expect(my_cool_list.videos).to respond_to(:reverse!)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.reverse!
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.reverse!
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_list.videos.map(&:id))
      videos.reverse!
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.reverse!
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.reverse!).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.reverse!
      expect(videos).not_to be_loaded
    end
  end

  describe "rotate! method" do
    before do
      my_cool_list.videos << food_chain
      my_cool_list.save
    end
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to rotate! method" do
      expect(my_cool_list.videos).to respond_to(:rotate!)
    end

    describe "with count=1" do
      let(:expected_videos) { [something_big, food_chain, return_of_harmony] }

      it "should respond to rotate! method" do
        expect(my_cool_list.videos).to respond_to(:rotate!)
      end

      it "should reflect changes" do
        videos = my_cool_list.videos
        videos.rotate!
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        videos = my_cool_list.videos.load
        videos.rotate!
        expect(videos).to eq(expected_videos)
      end

      it "should modify to_sql" do
        videos = my_cool_list.videos
        expect(videos.to_sql).to have_sql_IN_stmt(my_cool_list.videos.map(&:id))
        videos.rotate!
        expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
      end

      it "should affect ids" do
        my_cool_list.videos.rotate!
        expect(my_cool_list.video_ids).to eq(expected_video_ids)
      end

      it "should return self" do
        videos = my_cool_list.videos
        expect(videos.rotate!).to eq(videos)
      end

      it "should reset loaded state" do
        videos = my_cool_list.videos.load
        expect(videos).to be_loaded
        videos.rotate!
        expect(videos).not_to be_loaded
      end
    end

    describe "with count=2" do
      let(:expected_videos) { [food_chain, return_of_harmony, something_big] }

      it "should reflect changes" do
        videos = my_cool_list.videos
        videos.rotate! 2
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        videos = my_cool_list.videos.load
        videos.rotate! 2
        expect(videos).to eq(expected_videos)
      end

      it "should modify to_sql" do
        videos = my_cool_list.videos
        expect(videos.to_sql).to have_sql_IN_stmt(my_cool_list.videos.map(&:id))
        videos.rotate! 2
        expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
      end

      it "should affect ids" do
        my_cool_list.videos.rotate! 2
        expect(my_cool_list.video_ids).to eq(expected_video_ids)
      end

      it "should return self" do
        videos = my_cool_list.videos
        expect(videos.rotate! 2).to eq(videos)
      end

      it "should reset loaded state" do
        videos = my_cool_list.videos.load
        expect(videos).to be_loaded
        videos.rotate! 2
        expect(videos).not_to be_loaded
      end
    end
  end

  describe "select! method" do
    let(:block) { proc { |video| video.title.include? "Something" } }

    it "should respond to select! method" do
      expect(my_cool_list.videos).to respond_to(:select!)
    end

    it "should return self if changes are made" do
      expect(my_cool_list.videos.select!(&block)).to eq(my_cool_list.videos)
    end

    it "should return nil if changes are not made" do
      expect(my_cool_list.videos.select!{ true }).to be_nil
    end

    it "should return enumerator when calling without block" do
      expect(my_cool_list.videos.select!).to be_a(Enumerator)
      expect(my_cool_list.videos.select!.inspect).to include("select!")
    end
  end

  describe "shift method" do
    let(:expected_videos) { my_cool_videos.drop 1 }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to shift method" do
      expect(my_cool_list.videos).to respond_to(:shift)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.shift
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.shift
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_videos.map(&:id))
      videos.shift
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.shift
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return shifted element" do
      videos = my_cool_list.videos
      expect(videos.shift).to eq(return_of_harmony)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.shift
      expect(videos).not_to be_loaded
    end
  end

  describe "shuffle! method" do
    before do
      my_cool_list.videos << food_chain
      my_cool_list.save
    end

    it "should respond to shuffle! method" do
      expect(my_cool_list.videos).to respond_to(:shuffle!)
    end

    it "should reflect changes" do
      is_changed = false
      10.times do
        old_videos = my_cool_list.videos.to_a
        my_cool_list.videos.shuffle!
        expect(my_cool_list.videos).to contain_exactly(something_big, return_of_harmony, food_chain)
        is_changed ||= old_videos != my_cool_list.videos.to_a
      end
      expect(is_changed).to eq(true)
    end

    it "should affect ids" do
      10.times do
        old_videos = my_cool_list.videos.to_a
        my_cool_list.videos.shuffle!
        expect(my_cool_list.videos.map(&:id)).to contain_exactly(*[something_big, return_of_harmony, food_chain].map(&:id))
        is_changed ||= old_videos == my_cool_list.videos
      end
    end

    it "should return self" do
      expect(my_cool_list.videos.shuffle!).to eq(my_cool_list.videos)
    end
  end

  describe "uniq! method" do
    let(:expected_videos) { [return_of_harmony, something_big, food_chain] }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    before do
      my_cool_list.videos << something_big << food_chain
    end

    it "should respond to uniq! method" do
      expect(my_cool_list.videos).to respond_to(:uniq!)
    end

    describe "when calling without block" do
      it "should reflect changes" do
        videos = my_cool_list.videos
        videos.uniq!
        expect(videos).to eq(expected_videos)
      end

      it "should reflect changes when loaded" do
        videos = my_cool_list.videos.load
        videos.uniq!
        expect(videos).to eq(expected_videos)
      end

      it "should modify to_sql" do
        videos = my_cool_list.videos
        expect(videos.to_sql).to have_sql_IN_stmt(my_cool_list.videos.map(&:id))
        videos.uniq!
        expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
      end

      it "should affect ids" do
        my_cool_list.videos.uniq!
        expect(my_cool_list.video_ids).to eq(expected_video_ids)
      end

      it "should return self" do
        videos = my_cool_list.videos
        expect(videos.uniq!).to eq(videos)
      end

      it "should reset loaded state" do
        videos = my_cool_list.videos.load
        expect(videos).to be_loaded
        videos.uniq!
        expect(videos).not_to be_loaded
      end
    end

    describe "when calling with block" do
      let(:block) do
        proc { |video| video.id % 2 }
      end

      it "should reflect changes" do
        my_cool_list.videos.uniq!(&block)
        expect(my_cool_list.videos).to eq([return_of_harmony, something_big])
      end

      it "should affect ids" do
        my_cool_list.videos.uniq!(&block)
        expect(my_cool_list.videos.map(&:id)).to eq([return_of_harmony, something_big].map(&:id))
      end
    end
  end

  describe "unshift method" do
    let(:other_videos) { [escape_from_the_citadel, food_chain] }
    let(:expected_videos) { other_videos + my_cool_videos }
    let(:expected_video_ids) { expected_videos.map(&:id) }

    it "should respond to unshift method" do
      expect(my_cool_list.videos).to respond_to(:unshift)
    end

    it "should reflect changes" do
      videos = my_cool_list.videos
      videos.unshift(*other_videos)
      expect(videos).to eq(expected_videos)
    end

    it "should reflect changes when loaded" do
      videos = my_cool_list.videos.load
      videos.unshift(*other_videos)
      expect(videos).to eq(expected_videos)
    end

    it "should modify to_sql" do
      videos = my_cool_list.videos
      expect(videos.to_sql).to have_sql_IN_stmt(my_cool_list.videos.map(&:id))
      videos.unshift(*other_videos)
      expect(videos.to_sql).to have_sql_IN_stmt(expected_videos.map(&:id))
    end

    it "should affect ids" do
      my_cool_list.videos.unshift(*other_videos)
      expect(my_cool_list.video_ids).to eq(expected_video_ids)
    end

    it "should return self" do
      videos = my_cool_list.videos
      expect(videos.unshift(*other_videos)).to eq(videos)
    end

    it "should reset loaded state" do
      videos = my_cool_list.videos.load
      expect(videos).to be_loaded
      videos.unshift(*other_videos)
      expect(videos).not_to be_loaded
    end
  end
end
