let sanity_check () =
  let expected = 5 in
  let actual = 2 + 3 in
  Alcotest.(check int) "sanity check" expected actual

let () = Alcotest.run "serde-melange Test" [
    "Basic", [Alcotest.test_case "sanity check" `Quick sanity_check]
  ]
  
