# Standard Library requirements
require 'fileutils'
require 'base64'
require 'yaml'
require 'ostruct'
require 'singleton'

# External Requirements
require 'colorize'
require 'aws-sdk'

# Internal Requirements
require 'mnemosyne/version'
require 'mnemosyne/exception'
require 'mnemosyne/config'
Mnemosyne.config.load # Load config before requiring other classes
require 'mnemosyne/clients/ec2'
require 'mnemosyne/clients/rds'
require 'mnemosyne/resources/ec2_instance'
require 'mnemosyne/resources/rds_instance'
