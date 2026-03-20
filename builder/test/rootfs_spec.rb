require 'serverspec'
set :backend, :exec

describe file('etc/hostname') do
  it { should be_file }
  it { should be_mode 644 }
  it { should be_owned_by 'root' }
  its(:content) { should contain /^#{ENV['ALPINE_HOSTNAME']}$/ }
end

describe file('bin/bash') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode 755 }
end

describe file('etc/apk/repositories') do
  it { should be_file }
  its(:content) { should contain 'dl-cdn.alpinelinux.org/alpine' }
  its(:content) { should contain '/main' }
  its(:content) { should contain '/community' }
end

describe file('etc/network/interfaces') do
  it { should be_file }
  its(:content) { should contain /auto eth0/ }
  its(:content) { should contain /iface eth0 inet dhcp/ }
end

describe file('etc/shadow') do
  it { should be_file }
  its(:content) { should contain /^root:/ }
end

describe file('etc/skel/.bashrc') do
  it { should be_file }
end

describe file('etc/skel/.profile') do
  it { should be_file }
end

describe file('etc/skel/.bash_prompt') do
  it { should be_file }
end

describe file('etc/motd') do
  it { should be_file }
  its(:content) { should contain /^AlpineOS / }
end

describe file('etc/issue') do
  it { should be_file }
  its(:content) { should contain /^AlpineOS / }
end

describe file('etc/issue.net') do
  it { should be_file }
  its(:content) { should contain /^AlpineOS / }
end

describe file('etc/os-release') do
  it { should be_file }
  its(:content) { should contain /ID=alpine/ }
  its(:content) { should contain /ALPINE_OS=/ }
  its(:content) { should contain /ALPINE_OS_VERSION=/ }
end

describe file('usr/sbin/sshd') do
  it { should be_file }
end

describe file('etc/runlevels/default/sshd') do
  it { should be_symlink }
end

describe file('etc/runlevels/default/chronyd') do
  it { should be_symlink }
end

describe file('etc/runlevels/default/networking') do
  it { should be_symlink }
end
