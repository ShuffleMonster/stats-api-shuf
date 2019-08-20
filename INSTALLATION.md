## Installation (Ubuntu 18.04 x64)

### As root:
```
apt update
apt install -y build-essential
```

We are going to install Ruby using ruby-install, and we will choose the Ruby
version to run with chruby. Using these utilities will allow stats-api-shuf to
run with a recent version of Ruby, rather than trying to work with the older
version of Ruby that Ubuntu installs by default. (Our Ruby will be installed to
`/opt/rubies/ruby-2.6.3` [or whatever version], and will not interfere with the
system Ruby, if any.)

Install ruby-install, the Ruby installer: (You can check for newer versions at
https://github.com/postmodern/ruby-install/releases if you want, but this
version should work fine.)
```
V=0.7.0
wget -O ruby-install-$V.tar.gz https://github.com/postmodern/ruby-install/archive/v$V.tar.gz
tar -xzvf ruby-install-$V.tar.gz
cd ruby-install-$V
make install
cd -
```

Install chruby, the Ruby version chooser: (You can check for newer versions at
https://github.com/postmodern/chruby/releases if you want, but this version
should work fine.)
```
V=0.3.9
wget -O chruby-$V.tar.gz https://github.com/postmodern/chruby/archive/v$V.tar.gz
tar -xzvf chruby-$V.tar.gz
cd chruby-$V
make install
cd -
```

Install the latest Ruby:
```
ruby-install ruby
```

We are going to assume your user is called `ubuntu`. If not, change all
occurrences of the `ubuntu` username to your username (e.g., `bob`).

Add the following lines to `~/.profile` for user `ubuntu` in order to be able
to use the Ruby we installed:
```
source /usr/local/share/chruby/chruby.sh
chruby ruby
```

Update your environment. You can execute this command or log out and log back
in.
```
source ~/.profile
```

Check out the stats-api-shuf repo.
```
git clone https://github.com/ShuffleMonster/stats-api-shuf.git
cd stats-api-shuf # where the GitHub repo has been checked out
```

Install library dependencies in the current working directory (will not pollute
system gems, if any).
```
gem install bundler
bundle install --path vendor/bundle
```

Copy the example configuration files to the real ones.
```
cp config.example.yml config.yml
```
Configure `config.yml` and add your preferred web3 provider, e.g. Infura.


### Run as root:

Cause stats-api-shuf services to be started at boot time. (Note: If your
username is not `ubuntu`, fix the username and directory paths in
`systemd/stats-api-shuf.service`.)
```
cd /home/ubuntu/stats-api-shuf/
cp systemd/*.service /etc/systemd/system/
systemctl enable stats-api-shuf
```

Start the services.
```
systemctl start stats-api-shuf
```
