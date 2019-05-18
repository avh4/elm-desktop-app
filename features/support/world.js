const { setWorldConstructor } = require("cucumber");
const fs = require("fs");
const shell = require("shelljs");
const path = require("path");
const expect = require("expect");

class CustomWorld {
  constructor({attach}) {
    this.attach = attach;
    this.Main = {
      Msg: "type alias Msg = ()",
      main: {
        init: "((), Cmd.none)",
        update: "\\_ model -> (model, Cmd.none)",
        subscriptions: "\\_ -> Sub.none",
        view: "\\model -> { title = \"\", body = [ Html.text (Debug.toString model) ] }",
        persistence: "Nothing"
      }
    };
  }

  exec(string) {
    const result = shell.exec(string, {silent: true});
    this.attach(string);
    this.attach(result.stdout);
    this.attach(result.stderr);
    expect(result.code).toEqual(0);
  }

  runElmDesktopApp(args) {
    this.exec(path.join("node_modules", ".bin", "elm-desktop-app") + " " + args.join(" ")); // TODO: properly escape this
  }

  writeMain() {
    const Main = this.Main;
    return new Promise(function(resolve) {
      const stream = fs.createWriteStream("src/Main.elm");
      stream.write("import DesktopApp as App\n");
      stream.write("import DesktopApp.JsonMapping as JsonMapping\n");
      stream.write("import Html\n");
      stream.write("import Html.Events exposing (onClick)\n");
      stream.write("import Json.Encode as Json\n");
      stream.write(`${Main.Msg}\n`);
      stream.write("main = App.program\n");
      stream.write(`    { init = ${Main.main.init}\n`);
      stream.write(`    , update = ${Main.main.update}\n`);
      stream.write(`    , subscriptions = ${Main.main.subscriptions}\n`);
      stream.write(`    , view = ${Main.main.view}\n`);
      stream.write(`    , persistence = ${Main.main.persistence}\n`);
      stream.write("    }\n");
      stream.close();
      stream.on("finish", resolve);
    });
  }
}

setWorldConstructor(CustomWorld);
