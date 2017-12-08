dep "cleanup" do
  requires [
    "apt packages removed".with(%w[dovecot postfix apt-xapian-index python-xapian update-inetd cvs ghostscript libcups2 libcupsimage2]),
    "orphaned dirs deleted",
    "babushka caches removed"
  ]
end

dep "orphaned dirs deleted" do
  def paths
    %w[
      /var/cache/apt/archives/*deb
      /srv/cvs/
      /usr/java/
      /var/lib/mysql/
    ]
  end

  def to_remove
    paths.reject do |path|
      Dir[path].empty?
    end
  end
  met? do
    to_remove.empty?
  end
  meet do
    to_remove.each do |path|
      shell "rm -rf #{path}"
    end
  end
end
