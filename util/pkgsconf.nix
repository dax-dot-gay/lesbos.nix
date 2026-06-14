{
    inputs,
    system ? "x86_64-linux",
    extraOverlays ? [ ],
}:
import inputs.nixpkgs {
    inherit system;
    config = {
        allowUnfree = true;
    };
    overlays = [
        # Global overlays
    ]
    ++ extraOverlays;
}
