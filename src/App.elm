module App exposing
    ( program
    , File, jsonFile, JsonMapping, jsonMapping, withInt, staticString, with
    )

{-|

@docs program

@docs File, jsonFile, JsonMapping, jsonMapping, withInt, staticString, with

-}

import Browser
import DesktopApp.Ports as Ports
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


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
    , view : model -> Html msg
    , files : File model msg
    , noOp : msg
    }
    -> Program () model msg
program config =
    let
        saveFiles ( model, cmd ) =
            ( model
            , Cmd.batch
                [ cmd
                , [ config.files ]
                    |> List.map (\f -> encodeFile f model)
                    |> Ports.writeOut
                ]
            )

        decoders =
            [ config.files ]
                |> List.map (\(File filename (JsonMapping _ decode)) -> ( filename, decode ))
                |> Dict.fromList
    in
    Browser.document
        { init =
            \() ->
                let
                    ( model, cmd ) =
                        config.init
                in
                ( model
                , Cmd.batch
                    [ cmd
                    , [ config.files ]
                        |> List.map (\(File name _) -> name)
                        |> List.map Ports.loadFile
                        |> Cmd.batch
                    ]
                )
        , update =
            \msg model ->
                config.update msg model
                    |> saveFiles
        , subscriptions =
            let
                handleLoad ( filename, result ) =
                    case result of
                        Nothing ->
                            config.noOp

                        Just body ->
                            case Dict.get filename decoders of
                                Nothing ->
                                    -- Log error?
                                    config.noOp

                                Just decoder ->
                                    case Json.Decode.decodeString decoder body of
                                        Err err ->
                                            -- Log error?
                                            config.noOp

                                        Ok value ->
                                            value
            in
            \model ->
                Sub.batch
                    [ config.subscriptions model
                    , Ports.fileLoaded handleLoad
                    ]
        , view =
            \model ->
                { title = ""
                , body =
                    [ config.view model
                    ]
                }
        }


{-| Represents how a given `model` can be saved to and loaded from disk.
-}
type File model msg
    = File String (JsonMapping msg model)


encodeFile : File model msg -> model -> ( String, String )
encodeFile (File filename (JsonMapping fields _)) model =
    let
        json =
            Json.object
                (List.map (\( k, f ) -> ( k, f model )) fields)
    in
    ( filename, Json.encode 0 json )


{-| A `File` that is serialized as JSON.
-}
jsonFile : String -> (a -> msg) -> JsonMapping a a -> File a msg
jsonFile filename toMsg (JsonMapping encode decode) =
    File filename (JsonMapping encode (Json.Decode.map toMsg decode))


{-| Represents both how to encode `b` into JSON, and decode `a` from JSON.

Notably, when `a` and `b` are the same it specifies a two-way mapping to and from JSON
(which can then be used with [`jsonFile`](#jsonFile)).

-}
type JsonMapping a b
    = JsonMapping (List ( String, b -> Json.Value )) (Decoder a)


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
jsonMapping a =
    JsonMapping [] (Json.Decode.succeed a)


{-| Adds a field to an object. It will be represented in both your Elm model and in the JSON.
-}
with : String -> (x -> a) -> (a -> Json.Value) -> Decoder a -> JsonMapping (a -> b) x -> JsonMapping b x
with name get toJson fd (JsonMapping fields decoder) =
    JsonMapping (( name, get >> toJson ) :: fields) (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) decoder)


{-| Adds an integer field to an object. It will be represented in both your Elm model and in the JSON.
-}
withInt : String -> (x -> Int) -> JsonMapping (Int -> b) x -> JsonMapping b x
withInt name get =
    with name get Json.int Json.Decode.int


{-| Adds a static string field to an object. The field will not be represented in your Elm model,
but this exact field name and string value will be added to the written-out JSON file.
-}
staticString : String -> String -> JsonMapping a x -> JsonMapping a x
staticString name value (JsonMapping fields decoder) =
    JsonMapping (( name, \_ -> Json.string value ) :: fields) decoder
