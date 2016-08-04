# Mnemosyne

Mnemosyne, pronounced phonetically: "neh-mah-seh-nee", is a Greek Titaness and known as the personification of _memory_. This tool, named after her, is used to manage backups of EC2 instances (through AMIs) and RDS Instances (through DB snapshots). `Mnemosyne` uses the [AWS Ruby SDK](http://docs.aws.amazon.com/sdkforruby/api/index.html) to facilitate a sliding window of backups based on a YAML configuration file.

## Requirements

* Ruby 2.x or better
* AWS Credentials stored at `~/.aws/credentials`
* A Mnemosyne config file stored at `~/.mnemosyne/config.yml`
* The [bundler](http://bundler.io/) Ruby Gem

## Usage

### Installation

After downloading / cloning the source code, create and install the `Mnemosyne` gem:

    $ gem build mnemosyne.gemspec
    $ gem install mnemosyne-*.gem

Now, create a config file for `Mnemosyne`.

As an example, here is a sample config file:

    # config.yml
    
    ---
      region: us-west-2
      verbose: true
      rds:
        - id: 'app1-rds'
          max_backups: 14
      ec2:
        - id: i-abcd1234
          name: app1
          max_backups: 14
        - id: i-90214ee
          name: app2
          max_backups: 7
    

Given this example, `Mnemosyne` will operate in the `us-west-2` AWS region, and will operate on two EC2 instances. For the first instance, named by EC2 as `i-abcd1234`, `Mnemosyne` will refer to it as `app1`, will create an AMI without rebooting the instance and will retain 14 AMIs. `Mnemosyne` will also backup the associated RDS instance. This RDS instance is named by AWS as `app1-rds`, and `Mnemosyne` will retain 14 snapshots of this DB instance. For the second instance, named by AWS as `i-90214ee`, `Mnemosyne` will call it `app2`, will retain 7 backups.

The significance of the names `Mnemosyne` provides instances is that the AMIs are named (and tagged) based on the `name` attribute provided in the config file. It is worth noting that `id` for EC2 instances, and `id` for RDS instances are **provided by AWS** and should come from the AWS Admin Console.

### Running

To run, just execute the `mnemosyne` from anywhere (it should be put in your `$PATH`). Just be sure to place your config in `~/.mnemosyne/`, and call it `config.yml`.

    mnemosyne

The script will, by default, provide output based on what changes is makes. Eventually `--help` and `--debug` options will be added.
