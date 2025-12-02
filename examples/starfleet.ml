type rank =
  { rank_name : string
  ; rank_scores : string list
  }
[@@deriving serialize, deserialize]

type t =
  { name : string
  ; commisioned : bool
  ; updated_at : int64
  ; credits : int32 option
  ; keywords : string array
  ; rank : rank
  }
[@@deriving serialize, deserialize]

let () =
  let test_t =
    { name = "hello"
    ; commisioned = false
    ; updated_at = 1234567890L
    ; credits = None
    ; keywords = [| "foo"; "bar"; "baz" |]
    ; rank = { rank_name = "ensign"; rank_scores = [ "A"; "B"; "C"; "D"; "E" ] }
    }
  in

  match Serde_json.to_string serialize_t test_t with
  | Ok json ->
    Js.log json;

    (match Serde_json.of_string deserialize_t json with
    | Ok deserialized ->
      Js.log "Deserialized successfully!";
      Js.log deserialized;

      let matches =
        deserialized.name = test_t.name
        && deserialized.commisioned = test_t.commisioned
        && deserialized.updated_at = test_t.updated_at
        && deserialized.credits = test_t.credits
        && deserialized.rank.rank_name = test_t.rank.rank_name
      in
      if matches
      then Js.log "Round-trip successful!"
      else Js.log "Round-trip failed - values don't match"
    | Error err ->
      Js.log "Deserialization failed:";
      Js.log2 "  Error:" err)
  | Error err ->
    Js.log "Serialization failed:";
    Js.log2 "  Error:" err
