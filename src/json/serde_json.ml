open Serde

type deserializer_state =
  { json : Js.Json.t
  ; mutable current : Js.Json.t
  ; mutable array_idx : int
  ; mutable object_keys : string array
  ; mutable key_idx : int
  }

type serializer_kind =
  | Array of Js.Json.t list ref
  | Object of (string * Js.Json.t) list ref
  | Root

type serializer_state =
  { mutable kind : serializer_kind
  ; mutable result : Js.Json.t option
  ; parent : serializer_state option
  }

let ( let* ) = Result.bind

module rec Json_serializer :
  (Ser.Serializer with type output = unit and type state = serializer_state) =
struct
  type output = unit
  type state = serializer_state

  let nest state = { kind = Root; result = None; parent = Some state }

  let set_result state json =
    state.result <- Some json;
    (* Also propagate to parent if we're a nested state *)
    (match state.parent with
    | Some parent -> parent.result <- Some json
    | None -> ());
    match state.kind with
    | Array arr -> arr := json :: !arr
    | Object _fields -> ()
    | Root -> ()

  let serialize_bool _ctx state b =
    let json = Js.Json.boolean b in
    set_result state json;
    Ok ()

  let serialize_int8 _ctx state c =
    let json = Js.Json.number (float_of_int (Char.code c)) in
    set_result state json;
    Ok ()

  let serialize_int16 _ctx state i =
    let json = Js.Json.number (float_of_int i) in
    set_result state json;
    Ok ()

  let serialize_int31 _ctx state i =
    let json = Js.Json.number (float_of_int i) in
    set_result state json;
    Ok ()

  let serialize_int32 _ctx state i =
    let json = Js.Json.number (Int32.to_float i) in
    set_result state json;
    Ok ()

  let serialize_int64 _ctx state i =
    let json = Js.Json.number (Int64.to_float i) in
    set_result state json;
    Ok ()

  let serialize_float _ctx state f =
    let json = Js.Json.number f in
    set_result state json;
    Ok ()

  let serialize_string _ctx state s =
    let json = Js.Json.string s in
    set_result state json;
    Ok ()

  let serialize_none _ctx state =
    let json = Js.Json.null in
    set_result state json;
    Ok ()

  let serialize_some _ctx state f =
    let nested_state = nest state in
    let nested_ctx =
      Ser.Ctx
        ( Ser.serializer (fun _ _ -> Ok ())
        , (module Json_serializer)
        , nested_state )
    in
    let* () = f nested_ctx in
    match nested_state.result with
    | Some value ->
      set_result state value;
      Ok ()
    | None -> Error (`Msg "serialize_some: no result from nested serialization")

  let serialize_sequence ctx state ~size:_ f =
    let arr = ref [] in
    let old_kind = state.kind in
    state.kind <- Array arr;
    let* () = f ctx in
    state.kind <- old_kind;
    let json = Js.Json.array (Array.of_list (List.rev !arr)) in
    set_result state json;
    Ok ()

  let serialize_element ctx _state f = f ctx

  let serialize_unit_variant _ctx state ~var_type:_ ~cstr_idx:_ ~cstr_name =
    let json = Js.Json.string cstr_name in
    set_result state json;
    Ok ()

  let serialize_newtype_variant ctx state ~var_type:_ ~cstr_idx:_ ~cstr_name f =
    let* () = f ctx in
    let value = Option.get state.result in
    let obj = Js.Dict.empty () in
    Js.Dict.set obj cstr_name value;
    let json = Js.Json.object_ obj in
    set_result state json;
    Ok ()

  let serialize_tuple_variant
        ctx
        state
        ~var_type:_
        ~cstr_idx:_
        ~cstr_name
        ~size:_
        f
    =
    let arr = ref [] in
    let old_kind = state.kind in
    state.kind <- Array arr;
    let* () = f ctx in
    state.kind <- old_kind;
    let arr_json = Js.Json.array (Array.of_list (List.rev !arr)) in
    let obj = Js.Dict.empty () in
    Js.Dict.set obj cstr_name arr_json;
    let json = Js.Json.object_ obj in
    set_result state json;
    Ok ()

  let serialize_record_variant
        ctx
        state
        ~var_type:_
        ~cstr_idx:_
        ~cstr_name
        ~size:_
        f
    =
    let fields = ref [] in
    let old_kind = state.kind in
    state.kind <- Object fields;
    let* () = f ctx in
    state.kind <- old_kind;
    let obj = Js.Dict.empty () in
    List.iter (fun (k, v) -> Js.Dict.set obj k v) (List.rev !fields);
    let rec_json = Js.Json.object_ obj in
    let wrapper = Js.Dict.empty () in
    Js.Dict.set wrapper cstr_name rec_json;
    let json = Js.Json.object_ wrapper in
    set_result state json;
    Ok ()

  let serialize_record ctx state ~rec_type:_ ~size:_ f =
    let fields = ref [] in
    let old_kind = state.kind in
    state.kind <- Object fields;
    let* () = f ctx in
    state.kind <- old_kind;
    let obj = Js.Dict.empty () in
    List.iter (fun (k, v) -> Js.Dict.set obj k v) (List.rev !fields);
    let json = Js.Json.object_ obj in
    set_result state json;
    Ok ()

  let serialize_field ctx state ~name f =
    (* Save current result, call f which will set a new result, then capture
       it *)
    let old_result = state.result in
    state.result <- None;
    let* () = f ctx in
    let value = Option.get state.result in
    state.result <- old_result;
    (match state.kind with
    | Object fields -> fields := (name, value) :: !fields
    | _ -> ());
    Ok ()
end

and Json_deserializer : (De.Deserializer with type state = deserializer_state) =
struct
  type state = deserializer_state

  let nest state =
    { state with current = state.current; array_idx = 0; key_idx = 0 }

  let deserialize_bool _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONTrue -> Ok true
    | Js.Json.JSONFalse -> Ok false
    | _ -> Error `invalid_field_type

  let deserialize_int8 _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONNumber n -> Ok (Char.chr (int_of_float n))
    | _ -> Error `invalid_field_type

  let deserialize_int16 _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONNumber n -> Ok (int_of_float n)
    | _ -> Error `invalid_field_type

  let deserialize_int31 _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONNumber n -> Ok (int_of_float n)
    | _ -> Error `invalid_field_type

  let deserialize_int32 _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONNumber n -> Ok (Int32.of_float n)
    | _ -> Error `invalid_field_type

  let deserialize_int64 _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONNumber n -> Ok (Int64.of_float n)
    | _ -> Error `invalid_field_type

  let deserialize_float _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONNumber n -> Ok n
    | _ -> Error `invalid_field_type

  let deserialize_string _ctx state =
    match Js.Json.classify state.current with
    | Js.Json.JSONString s -> Ok s
    | _ -> Error `invalid_field_type

  let deserialize_option _ctx state de =
    match Js.Json.classify state.current with
    | Js.Json.JSONNull -> Ok None
    | _ ->
      let nested = nest state in
      let nested_ctx = De.Ctx ((module Json_deserializer), nested) in
      let* value = de nested_ctx in
      Ok (Some value)

  let deserialize_sequence _ctx state ~size:_ f =
    match Js.Json.classify state.current with
    | Js.Json.JSONArray arr ->
      let size = Array.length arr in
      let seq_state = { state with array_idx = 0 } in
      let seq_ctx = De.Ctx ((module Json_deserializer), seq_state) in
      f ~size seq_ctx
    | _ -> Error `invalid_field_type

  let deserialize_element _ctx state de =
    match Js.Json.classify state.current with
    | Js.Json.JSONArray arr ->
      if state.array_idx < Array.length arr
      then begin
        let elem = Array.unsafe_get arr state.array_idx in
        state.array_idx <- state.array_idx + 1;
        let elem_state = { state with current = elem; array_idx = 0 } in
        let elem_ctx = De.Ctx ((module Json_deserializer), elem_state) in
        let* value = de elem_ctx in
        Ok (Some value)
      end
      else Ok None
    | _ -> Error `invalid_field_type

  let deserialize_variant _ctx state de ~name:_ ~variants:_ =
    de (De.Ctx ((module Json_deserializer), state))

  let deserialize_unit_variant _ctx _state = Ok ()

  let deserialize_newtype_variant _ctx state de =
    match Js.Json.classify state.current with
    | Js.Json.JSONObject obj ->
      let keys = Js.Dict.keys obj in
      if Array.length keys = 1
      then
        let key = Array.unsafe_get keys 0 in
        match Js.Dict.get obj key with
        | Some value ->
          let nested =
            { state with current = value; array_idx = 0; key_idx = 0 }
          in
          let nested_ctx = De.Ctx ((module Json_deserializer), nested) in
          de nested_ctx
        | None -> Error `missing_field
      else Error `invalid_tag
    | _ -> Error `invalid_tag

  let deserialize_tuple_variant _ctx state ~size de =
    deserialize_newtype_variant _ctx state (fun ctx -> de ~size ctx)

  let deserialize_record_variant _ctx state ~size de =
    deserialize_tuple_variant _ctx state ~size de

  let deserialize_record _ctx state ~name:_ ~size:_ de =
    match Js.Json.classify state.current with
    | Js.Json.JSONObject obj ->
      let keys = Js.Dict.keys obj in
      let record_state = { state with object_keys = keys; key_idx = 0 } in
      let record_ctx = De.Ctx ((module Json_deserializer), record_state) in
      de record_ctx
    | _ -> Error `invalid_field_type

  let deserialize_field _ctx state ~name de =
    match Js.Json.classify state.current with
    | Js.Json.JSONObject obj ->
      (match Js.Dict.get obj name with
      | Some value ->
        let field_state =
          { state with current = value; array_idx = 0; key_idx = 0 }
        in
        let field_ctx = De.Ctx ((module Json_deserializer), field_state) in
        de field_ctx
      | None -> Error `missing_field)
    | _ -> Error `invalid_field_type

  let deserialize_key _ctx state visitor =
    if state.key_idx < Array.length state.object_keys
    then begin
      let key = Array.unsafe_get state.object_keys state.key_idx in
      state.key_idx <- state.key_idx + 1;
      let key_ctx = De.Ctx ((module Json_deserializer), state) in
      let* value = visitor.Visitor.visit_string key_ctx key in
      Ok (Some value)
    end
    else Ok None

  let deserialize_identifier _ctx state visitor =
    match Js.Json.classify state.current with
    | Js.Json.JSONString s ->
      let ctx = De.Ctx ((module Json_deserializer), state) in
      visitor.Visitor.visit_string ctx s
    | Js.Json.JSONNumber n ->
      let ctx = De.Ctx ((module Json_deserializer), state) in
      visitor.Visitor.visit_int ctx (int_of_float n)
    | _ -> Error `invalid_field_type

  let deserialize_ignored_any _ctx _state = Ok ()
end

let of_string de str =
  try
    let json = Js.Json.parseExn str in
    let state =
      { json; current = json; array_idx = 0; object_keys = [||]; key_idx = 0 }
    in
    deserialize (module Json_deserializer) state de
  with
  | _ -> Error (`Msg "Invalid JSON")

let to_string ser value =
  let state : Json_serializer.state =
    { kind = Root; result = None; parent = None }
  in
  let* () = serialize (module Json_serializer) state ser value in
  match state.result with
  | Some json -> Ok (Js.Json.stringify json)
  | None -> Error (`Msg "Serialization produced no result")

let of_json de json =
  let state : deserializer_state =
    { json; current = json; array_idx = 0; object_keys = [||]; key_idx = 0 }
  in
  deserialize (module Json_deserializer) state de

let to_json ser value =
  let state : Json_serializer.state =
    { kind = Root; result = None; parent = None }
  in
  let* () = serialize (module Json_serializer) state ser value in
  match state.result with
  | Some json -> Ok json
  | None -> Error (`Msg "Serialization produced no result")
