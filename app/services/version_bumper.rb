class VersionBumper
  def initialize(current_version, feedbacks)
    @major, @minor, @patch = current_version.split(".").map(&:to_i)
    @feedbacks = feedbacks
  end

  def next_version
    b = @feedbacks.where(category: :bug).count
    m = @feedbacks.where(category: :melhoria).count
    c = @feedbacks.where(severity: :critica).count

    # Regras de negócio
    return bump_major if c >= 1
    return bump_minor if b >= 5 || m >= 3

    bump_patch
  end

  private

  def bump_major
    "#{@major + 1}.0.0"
  end

  def bump_minor
    "#{@major}.#{@minor + 1}.0"
  end

  def bump_patch
    "#{@major}.#{@minor}.#{@patch + 1}"
  end
end
