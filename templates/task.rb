meta :task do
  accepts_block_for :run
  template {
    met? { @run }
    meet { invoke(:run).tap { @run = true } }
  }
end
