module DesktopApp exposing
    ( program, Model
    , File, jsonFile, JsonMapping, jsonMapping, withInt, withString, staticString, with
    )

{-|

@docs program, Model

@docs File, jsonFile, JsonMapping, jsonMapping, withInt, withString, staticString, with

-}

import Browser
import DesktopApp.Ports as Ports
import DesktopApp.Testable as DesktopApp
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


{-| This is the Model type for your Elm program when using `DesktopApp.program`

For example:

    module Main exposing (main)

    import DesktopApp

    type alias Model = { ... }
    type Msg = ...
    type alias Flags = ...

    main : Program Flags (DesktopApp.Model Model) Msg
    main =
        DesktopApp.program { ... }

-}
type alias Model yourModel =
    DesktopApp.Model yourModel


{-| Use this to define your `main` in your `Main.elm` file, and then use the `elm-desktop-app`
command line tool to build your app.

  - `init`, `update`, `subscription`, `view`: These are the same as in any Elm program.
  - `noOp`: You must provide a msg that will do nothing (so that I can propertly wire up the electron ports).
  - `files`: This specifies how the data for you app will be saved to the user's filesystem.

-}
program :
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Browser.Document msg
    , files : File model msg
    , noOp : msg
    }
    -> Program () (Model model) msg
program config =
    let
        p =
            DesktopApp.program config

        performAll ( cmd, effects ) =
            Cmd.batch
                [ cmd
                , effects
                    |> List.map perform
                    |> Cmd.batch
                ]

        perform effect =
            case effect of
                DesktopApp.WriteUserData content ->
                    Ports.writeUserData content

                DesktopApp.LoadUserData ->
                    Ports.loadUserData ()
    in
    Browser.document
        { init =
            \flags ->
                p.init flags
                    |> Tuple.mapSecond performAll
        , subscriptions = p.subscriptions
        , update =
            \msg model ->
                p.update msg model
                    |> Tuple.mapSecond performAll
        , view = p.view
        }


{-| Represents how a given `model` can be saved to and loaded from disk.
-}
type alias File model msg =
    DesktopApp.File model msg


{-| A `File` that is serialized as JSON.
-}
jsonFile : (b -> msg) -> JsonMapping b a -> File a msg
jsonFile =
    DesktopApp.jsonFile


{-| Represents both how to encode `b` into JSON, and decode `a` from JSON.

Notably, when `a` and `b` are the same it specifies a two-way mapping to and from JSON
(which can then be used with [`jsonFile`](#jsonFile)).

-}
type alias JsonMapping a b =
    DesktopApp.JsonMapping a b


{-| Creates a trivial `JsonMapping`.
This, along with `withInt`, `staticString`, `with` make up a pipeline-style API
which can be used like this:

    import App exposing (JsonMapping, jsonMapping, withInt)

    type alias MyData =
        { total : Int
        , count : Int
        }

    myJsonMapping : JsonMapping MyData MyData
    myJsonMapping =
        jsonMapping MyData
            |> withInt "total" .total
            |> withInt "count" .count

-}
jsonMapping : a -> JsonMapping a b
jsonMapping =
    DesktopApp.jsonMapping


{-| Adds a field to an object. It will be represented in both your Elm model and in the JSON.
-}
with : String -> (x -> a) -> (a -> Json.Value) -> Decoder a -> JsonMapping (a -> b) x -> JsonMapping b x
with =
    DesktopApp.with


{-| Adds an integer field to an object. It will be represented in both your Elm model and in the JSON.
-}
withInt : String -> (x -> Int) -> JsonMapping (Int -> b) x -> JsonMapping b x
withInt =
    DesktopApp.withInt


{-| Adds an string field to an object. It will be represented in both your Elm model and in the JSON.
-}
withString : String -> (x -> String) -> JsonMapping (String -> b) x -> JsonMapping b x
withString =
    DesktopApp.withString


{-| Adds a static string field to an object. The field will not be represented in your Elm model,
but this exact field name and string value will be added to the written-out JSON file.
-}
staticString : String -> String -> JsonMapping a x -> JsonMapping a x
staticString =
    DesktopApp.staticString
