dep 'cleanup' do
  requires [
    'unwanted packages removed',
    'orphaned dirs deleted',
    'benhoskings:babushka caches removed'
  ]
end

dep 'unwanted packages removed', :template => 'benhoskings:apt_packages_removed', :for => :apt do
  removes %w[postfix apt-xapian-index python-xapian update-inetd cvs ghostscript libcups2 libcupsimage2]
end

dep 'orphaned dirs deleted' do
  def dirs
    %w[
      /var/cache/apt/archives/*deb
      /srv/cvs/
      /usr/java/
      /var/lib/mysql/
    ]
  end
  met? {
    to_remove.empty?
  }
  meet {
    to_remove.each {|path|
      shell %Q{rm -rf "#{path}"}
    }
  }
end
