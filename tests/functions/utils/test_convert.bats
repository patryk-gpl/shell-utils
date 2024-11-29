#!/usr/bin/env bats

repo_root=$(git rev-parse --show-toplevel)

load "$repo_root/functions/utils/decode.sh"
load "$repo_root/functions/utils/convert.sh"

@test "decode_base64" {
  result=$(decode_base64 "bXlWYXIK")
  [ "$result" = "myVar" ]
}

@test "decode_base64 with double encoding" {
  double_encoded=$(echo -n "myVar" | base64 | base64)
  result=$(decode_base64 "$double_encoded")
  [ "$result" = "myVar" ]
}

@test "decode_base64 with triple encoding" {
  triple_encoded=$(echo -n "myVar" | base64 | base64 | base64)
  result=$(decode_base64 "$triple_encoded")
  [ "$result" = "myVar" ]
}


@test "convert_camel_case_to_kebab_case" {
  result=$(convert_camel_case_to_kebab_case "myVar")
  [ "$result" = "my-var" ]
}

@test "convert_camel_case_to_snake_case" {
  result=$(convert_camel_case_to_snake_case "myVar")
  [ "$result" = "my_var" ]
}

@test "convert_kebap_case_to_camel_case" {
  result=$(convert_kebap_case_to_camel_case "my-var")
  [ "$result" = "myVar" ]
}

@test "convert_kebab_case_to_snake_case" {
  result=$(convert_kebab_case_to_snake_case "my-var")
  [ "$result" = "my_var" ]
}

@test "convert_snake_case_to_camel_case" {
  result=$(convert_snake_case_to_camel_case "my_var")
  [ "$result" = "myVar" ]
}

@test "convert_snake_case_to_kebab_case" {
  result=$(convert_snake_case_to_kebab_case "my_var")
  [ "$result" = "my-var" ]
}

@test "convert_snake_case_to_upper_snake_case" {
  result=$(convert_snake_case_to_upper_snake_case "my_var")
  [ "$result" = "MY_VAR" ]
}

@test "convert_upper_snake_case_to_snake_case" {
  result=$(convert_upper_snake_case_to_snake_case "MY_VAR")
  [ "$result" = "my_var" ]
}
