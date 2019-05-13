const { setWorldConstructor } = require("cucumber");
const fs = require("fs");
const shell = require("shelljs");
const path = require("path");
const expect = require("expect");

class CustomWorld {
  constructor() {
    this.Main = {
      Msg: "type alias Msg = ()",
      main: {
        init: "((), Cmd.none)",
        update: "\\_ model -> (model, Cmd.none)",
        subscriptions: "\\_ -> Sub.none",
        view: "\\model -> Html.text (Debug.toString model)",
        files: "Debug.todo \"\"",
        noOp: "()"
      }
    };
  }

  runElmDesktopApp(args) {
    const result = shell.exec(path.join(__dirname, "..", "..", "cli.js") + " " + args.join(" ")); // TODO: properly escape this
    expect(result.code).toEqual(0);
  }

  writeMain() {
    const Main = this.Main;
    return new Promise(function(resolve) {
      const stream = fs.createWriteStream("Main.elm");
      stream.write("import App\n");
      stream.write("import Html\n");
      stream.write("import Html.Events exposing (onClick)\n");
      stream.write("import Json.Encode as Json\n");
      stream.write(`${Main.Msg}\n`);
      stream.write("main = App.program\n");
      stream.write(`    { init = ${Main.main.init}\n`);
      stream.write(`    , update = ${Main.main.update}\n`);
      stream.write(`    , subscriptions = ${Main.main.subscriptions}\n`);
      stream.write(`    , view = ${Main.main.view}\n`);
      stream.write(`    , files = ${Main.main.files}\n`);
      stream.write(`    , noOp = ${Main.main.noOp}\n`);
      stream.write("    }\n");
      stream.close();
      stream.on("finish", resolve);
    });
  }
}

setWorldConstructor(CustomWorld);
