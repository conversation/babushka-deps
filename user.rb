dep 'deploy user setup', :env, :keys do
  requires [
    # Shell config, etc.
    'benhoskings:user setup'.with(:key => keys),

    # Add a corresponding DB user.
    'benhoskings:postgres access',

    # Set RACK_ENV and friends.
    'conversation:app env vars set'.with(:env => env),

    # Configure the ~/current repo to accept deploys.
    'benhoskings:web repo'
  ]
end
