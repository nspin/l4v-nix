{ lib
, writeShellApplication
, xauth
}:

writeShellApplication {
  name = "container-xauthority";
  runtimeInputs = [
    xauth
  ];
  checkPhase = false;
  text = builtins.readFile ./x.sh;
}
