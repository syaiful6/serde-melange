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
      |> toEqual (Ok { tEsTinG1 = false })));

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
      |> toEqual (Ok {|{"TESTING1":false}|})))
