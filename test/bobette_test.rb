require File.dirname(__FILE__) + "/helper"

class BobetteTest < Bobette::TestCase
  def setup
    super

    @metadata = {}
    @builds   = {}

    Beacon.watch(:start) { |commit_id, commit_info|
      @metadata[commit_id] = commit_info
    }

    Beacon.watch(:finish) { |commit_id, status, output|
      @builds[commit_id] = [status ? :successful : :failed, output]
    }
  end

  def teardown
    @repo.destroy
  end

  def test_valid_payload
    assert post("/", :payload => payload(@repo).to_json).ok?

    assert_equal 4, @metadata.count
    assert_equal 4, @builds.count

    commit = @repo.head

    assert_equal :failed, @builds[commit].first
    assert_equal "Running tests...\n", @builds[commit].last
    assert_equal "This commit will fail", @metadata[commit][:message]
  end

  def test_invalid_payload
    assert post("/").client_error?
    assert post("/", :payload => "</3").client_error?
  end

  def test_with_em
    require "eventmachine"

    EM.run {
      assert post("/", :payload => payload(@repo).to_json).ok?
      EM.stop_event_loop
    }
  end
end
