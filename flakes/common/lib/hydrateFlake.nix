outputs:
{ self, ... }@inputs:
let
    resolved = outputs inputs;
in
(resolved // { })
