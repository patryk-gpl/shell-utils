#!/usr/bin/env bash
# This file contains functions to work with AWS IAM (Identity and Access Management)

 aws_get_caller_identity() {
   aws sts get-caller-identity | jq .
 }
