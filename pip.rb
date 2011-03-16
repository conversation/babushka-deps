meta :pip do
  accepts_list_for :installs, :basename
  accepts_list_for :provides, :basename
  template {
    met? { provided? }
    meet {
      installs.each {|pippable|
        shell "pip install #{pippable}", sudo: !File.writable?(which('pip'))
      }
    }
  }
end
