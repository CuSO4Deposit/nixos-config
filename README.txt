                                  NixOS config

My NixOS configurations are organized with host-specific settings stored in the
`hosts/` directory.  When making updates to shared configurations, first
implement the changes in the main branch, then rebase the host-specific
branches onto the updated main branch.
