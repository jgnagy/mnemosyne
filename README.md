# Mnemosyne

Mnemosyne, pronounced phonetically: "neh-mah-seh-nee", is a Greek Titaness and known as the personification of _memory_. This tool, named after her, is used to manage backups of EC2 instances (through AMIs) and RDS Instances (through DB snapshots). `Mnemosyne` uses the [AWS Ruby SDK](http://docs.aws.amazon.com/sdkforruby/api/index.html) to facilitate a sliding window of backups based on a YAML configuration file.

## Requirements

* Ruby 2.x or better
* AWS Credentials stored at `~/.aws/credentials`
* The [bundler](http://bundler.io/) Ruby Gem

## Usage

### Installation

After downloading / cloning the source code, install `Mnemosyne`'s dependencies:

    $ bundle install

Now, create a config file for `Mnemosyne`.

As an example, here is a sample config file:

    # config.yml
    
    ---
      region: us-west-2
      instances:
        - id: i-abcdef12
          name: app1
          reboot: false
          max_backups: 7
          rds:
            instance: 'app1-rds'
            max_backups: 14
        - id: i-9876abcd
          name: app2
          reboot: true
          max_backups: 3
    

Given this example, `Mnemosyne` will operate in the `us-west-2` AWS region, and will operate on two EC2 instances. For the first instance, named by EC2 as `i-abcdef12`, `Mnemosyne` will refer to it as `app1`, will create an AMI without rebooting the instance, will retain 7 AMIs and will backup the associated RDS instance. This RDS instance is named by AWS as `app1-rds`, and `Mnemosyne` will retain 14 snapshots of this DB instance. For the second instance, named by AWS as `i-9876abcd`, `Mnemosyne` will call it `app2`, **will** reboot the instance to do a solid backup, and will retain 3 backups.

The significance of the names `Mnemosyne` provides instances is that the AMIs are named (and tagged) based on the `name` attribute provided in the config file. It is worth noting that `id` for EC2 instances, and `instance` for RDS instances are **provided by AWS** and should come from the AWS Admin Console.

### Running

To run, just execute the `mnemosyne.rb` file, optionally passing it a path to your config file. If your config file is the one provided with this repo, called `config.yml`, and if your current working directory the root of this repository, then you can simply run `mnemosyne.rb` without any arguments.

    ./mnemosyne.rb

The script will, by default, provide output based on what changes is makes. Eventually `--help` and `--debug` options will be added.
