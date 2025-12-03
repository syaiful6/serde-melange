open Jest
open Expect

type with_type_field = { type_ : string [@serde { rename = "type" }] }
[@@deriving serialize, deserialize]

type with_lowercase = { tEsTinG : bool }
[@@deriving serialize, deserialize] [@@serde { rename_all = "lowercase" }]

type with_unknown_keys = { known : string } [@@deriving serialize, deserialize]

type deny_unknown_keys = { know : string }
[@@deriving serialize, deserialize] [@@serde { deny_unknown_fields = true }]

type with_uppercase = { tEsTinG1 : bool }
[@@deriving serialize, deserialize] [@@serde { rename_all = "UPPERCASE" }]

type with_snakecase = { test_value : int }
[@@deriving serialize, deserialize] [@@serde { rename_all = "snake_case" }]

type with_camelcase = { camel_case : bool }
[@@deriving serialize, deserialize] [@@serde { rename_all = "camelCase" }]

type with_pascalcase = { pascal_case : string }
[@@deriving serialize, deserialize] [@@serde { rename_all = "PascalCase" }]

type with_kebabcase = { kebab_case : float }
[@@deriving serialize, deserialize] [@@serde { rename_all = "kebab-case" }]

type with_nested =
  { name : string
  ; camel_case : with_camelcase
  ; kebab_case : with_kebabcase
  }
[@@deriving serialize, deserialize] [@@serde { rename_all = "snake_case" }]

let () =
  describe "deserialize" (fun () ->
    test "rename field 'type'" (fun () ->
      let input = {| { "type": "example" } |} in
      expect @@ Serde_json.of_string deserialize_with_type_field input
      |> toEqual (Ok { type_ = "example" }));

    test "allow unknown keys" (fun () ->
      let input = {| { "known": "value", "unknown": 123 } |} in
      expect @@ Serde_json.of_string deserialize_with_unknown_keys input
      |> toEqual (Ok { known = "value" }));

    test "can deny unknown keys" (fun () ->
      let input = {| { "know": "value", "extra": 456 } |} in
      expect @@ Serde_json.of_string deserialize_deny_unknown_keys input
      |> toEqual (Error `invalid_tag));

    test "with lowercase" (fun () ->
      let input = {| { "testing": true } |} in
      expect @@ Serde_json.of_string deserialize_with_lowercase input
      |> toEqual (Ok { tEsTinG = true }));

    test "with uppercase" (fun () ->
      let input = {| { "TESTING1": false } |} in
      expect @@ Serde_json.of_string deserialize_with_uppercase input
      |> toEqual (Ok { tEsTinG1 = false }));

    test "with snake_case" (fun () ->
      let input = {| { "test_value": 42 } |} in
      expect @@ Serde_json.of_string deserialize_with_snakecase input
      |> toEqual (Ok { test_value = 42 }));

    test "with camelCase" (fun () ->
      let input = {| { "camelCase": true } |} in
      expect @@ Serde_json.of_string deserialize_with_camelcase input
      |> toEqual (Ok { camel_case = true }));

    test "with PascalCase" (fun () ->
      let input = {| { "PascalCase": "test" } |} in
      expect @@ Serde_json.of_string deserialize_with_pascalcase input
      |> toEqual (Ok { pascal_case = "test" }));

    test "with kebab-case" (fun () ->
      let input = {| { "kebab-case": 3.14 } |} in
      expect @@ Serde_json.of_string deserialize_with_kebabcase input
      |> toEqual (Ok { kebab_case = 3.14 }));

    test "with nested structs" (fun () ->
      let input =
        {| { "name": "example", "camel_case": { "camelCase": false }, "kebab_case": { "kebab-case": 2.71 } } |}
      in
      expect @@ Serde_json.of_string deserialize_with_nested input
      |> toEqual
           (Ok
              { name = "example"
              ; camel_case = { camel_case = false }
              ; kebab_case = { kebab_case = 2.71 }
              })));

  describe "serialize" (fun () ->
    test "rename field 'type'" (fun () ->
      let value = { type_ = "example" } in
      expect @@ Serde_json.to_string serialize_with_type_field value
      |> toEqual (Ok {|{"type":"example"}|}));

    test "with lowercase" (fun () ->
      let value = { tEsTinG = true } in
      expect @@ Serde_json.to_string serialize_with_lowercase value
      |> toEqual (Ok {|{"testing":true}|}));

    test "with uppercase" (fun () ->
      let value = { tEsTinG1 = false } in
      expect @@ Serde_json.to_string serialize_with_uppercase value
      |> toEqual (Ok {|{"TESTING1":false}|}));

    test "with snake_case" (fun () ->
      let value = { test_value = 42 } in
      expect @@ Serde_json.to_string serialize_with_snakecase value
      |> toEqual (Ok {|{"test_value":42}|}));

    test "with camelCase" (fun () ->
      let value = { camel_case = true } in
      expect @@ Serde_json.to_string serialize_with_camelcase value
      |> toEqual (Ok {|{"camelCase":true}|}));

    test "with PascalCase" (fun () ->
      let value = { pascal_case = "test" } in
      expect @@ Serde_json.to_string serialize_with_pascalcase value
      |> toEqual (Ok {|{"PascalCase":"test"}|}));

    test "with kebab-case" (fun () ->
      let value = { kebab_case = 3.14 } in
      expect @@ Serde_json.to_string serialize_with_kebabcase value
      |> toEqual (Ok {|{"kebab-case":3.14}|}));

    test "with nested structs" (fun () ->
      let value =
        { name = "example"
        ; camel_case = { camel_case = false }
        ; kebab_case = { kebab_case = 2.71 }
        }
      in
      expect @@ Serde_json.to_string serialize_with_nested value
      |> toEqual
           (Ok
              {|{"name":"example","camel_case":{"camelCase":false},"kebab_case":{"kebab-case":2.71}}|})))
