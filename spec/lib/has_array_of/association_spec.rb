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
    let!(:my_cool_video_ids) { my_cool_videos.map(&:id) }
    let!(:my_cool_list) {
      Playlist.create(video_ids: my_cool_video_ids.clone)
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

      it "should correctly deal with nil" do
        playlist = Playlist.create video_ids: [nil, something_big.id, nil]
        expect(playlist.videos).to eq([nil, something_big, nil])
        playlist = Playlist.create video_ids: [nil, nil, nil]
        expect(playlist.videos).to eq([nil, nil, nil])
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

      it "should correctly append nil values" do
        videos = my_cool_list.videos
        videos << nil
        expect(my_cool_list.video_ids).to eq([*my_cool_video_ids, nil])
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
        expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
        videos.delete something_big
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
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

      pending "chaining with other queries" do
        # TODO: decide what to do when chaining
        it "should work well with queries referencing fields other than primary_key" do
          videos = my_cool_list.videos.where("title like 'Adventure%'")
          expect {
            videos.delete something_big
          }.to change(videos, :count).by(-1)
        end

        it "should work well with queries referencing primary_key" do
          videos = adventure_time_season6.videos.where(id: mlp_videos.map(&:id))
          expect {
            videos.delete something_big
          }.to change(videos, :count).by(-1)
        end
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
        expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
        videos.delete_at 0
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
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

      pending "chaining with other queries" do
        # TODO: decide what to do when chaining
        it "should work well with queries referencing fields other than primary_key" do
          videos = my_cool_list.videos.where("title like 'Adventure%'")
          expect {
            videos.delete_at 0
          }.to change(videos, :count).by(-1)
        end

        it "should work well with queries referencing primary_key" do
          videos = adventure_time_season6.videos.where(id: mlp_videos.map(&:id))
          expect {
            videos.delete_at 0
          }.to change(videos, :count).by(-1)
        end
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
        expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
        videos.shift
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
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

      pending "chaining with other queries" do
        # TODO: decide what to do when chaining
        it "should work well with queries referencing fields other than primary_key" do
          videos = my_cool_list.videos.where("title like 'Adventure%'")
          expect {
            videos.shift
          }.to change(videos, :count).by(-1)
        end

        it "should work well with queries referencing primary_key" do
          videos = adventure_time_season6.videos.where(id: mlp_videos.map(&:id))
          expect {
            videos.shift
          }.to change(videos, :count).by(-1)
        end
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
        expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
        videos.pop
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
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

      pending "chaining with other queries" do
        # TODO: decide what to do when chaining
        it "should work well with queries referencing fields other than primary_key" do
          videos = my_cool_list.videos.where("title like 'Adventure%'")
          expect {
            videos.pop
          }.to change(videos, :count).by(-1)
        end

        it "should work well with queries referencing primary_key" do
          videos = adventure_time_season6.videos.where(id: mlp_videos.map(&:id))
          expect {
            videos.pop
          }.to change(videos, :count).by(-1)
        end
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
        expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
        videos.delete_if(&block)
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
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

      pending "chaining with other queries" do
        # TODO: decide what to do when chaining
        it "should work well with queries referencing fields other than primary_key" do
          videos = my_cool_list.videos.where("title like 'Adventure%'")
          expect {
            videos.delete_if(&block)
          }.to change(videos, :count).by(-1)
        end

        it "should work well with queries referencing primary_key" do
          videos = adventure_time_season6.videos.where(id: mlp_videos.map(&:id))
          expect {
            videos.delete_if(&block)
          }.to change(videos, :count).by(-1)
        end
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
        expect(videos.to_sql).to include("(#{my_cool_videos.map(&:id).join(', ')})")
        videos.keep_if(&block)
        expect(videos.to_sql).to include("(#{expected_videos.map(&:id).join(', ')})")
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

      pending "chaining with other queries" do
        # TODO: decide what to do when chaining
        it "should work well with queries referencing fields other than primary_key" do
          videos = my_cool_list.videos.where("title like 'Adventure%'")
          expect {
            videos.keep_if(&block)
          }.to change(videos, :count).by(-1)
        end

        it "should work well with queries referencing primary_key" do
          videos = adventure_time_season6.videos.where(id: mlp_videos.map(&:id))
          expect {
            videos.keep_if(&block)
          }.to change(videos, :count).by(-1)
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
  end

  describe "belongs_to_array_in_many scope" do
    pending "TODO"
  end
end
