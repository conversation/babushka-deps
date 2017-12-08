dep "babushka caches removed" do
  def paths
    %w[
      ~/.babushka/downloads/*
      ~/.babushka/build/*
    ]
  end

  def to_remove
    paths.reject do |p|
      Dir[p.p].empty?
    end
  end
  met? do
    to_remove.empty?
  end
  meet do
    to_remove.each do |path|
      shell %Q{rm -rf #{path}}
    end
  end
end
