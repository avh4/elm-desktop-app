module DesktopApp.Testable exposing
    ( Effect(..)
    , File
    , JsonMapping
    , Model
    , jsonFile
    , jsonMapping
    , program
    , staticString
    , with
    , withInt
    )

import DesktopApp.Ports as Ports
import Dict exposing (Dict)
import Html exposing (Html)
import Json.Decode exposing (Decoder)
import Json.Encode as Json


type Effect
    = WriteOut ( String, String )
    | LoadFile String


type Model yourModel
    = Model
        { appModel : yourModel
        , lastSaved : Dict String String
        }


program :
    { init : ( model, Cmd msg )
    , update : msg -> model -> ( model, Cmd msg )
    , subscriptions : model -> Sub msg
    , view : model -> Html msg
    , files : File model msg
    , noOp : msg
    }
    ->
        { init : () -> ( Model model, ( Cmd msg, List Effect ) )
        , subscriptions : Model model -> Sub msg
        , update : msg -> Model model -> ( Model model, ( Cmd msg, List Effect ) )
        , view : Model model -> { body : List (Html msg), title : String }
        }
program config =
    let
        saveFiles cmd (Model model) =
            -- TODO: is there a way we can check equality of the accessed fields in the JsonMapping, and avoid encoding the data to Json.Value and then to String if we don't need to?
            let
                ( newLastSaved, writeEffects ) =
                    [ config.files ]
                        |> List.foldl step ( model.lastSaved, [] )

                step file ( lastSaved, effects ) =
                    let
                        ( filename, newContent ) =
                            encodeFile file model.appModel
                    in
                    if Dict.get filename lastSaved == Just newContent then
                        -- This file hasn't changed, so do nothing
                        ( lastSaved, effects )

                    else
                        -- This file needs to be written out
                        ( Dict.insert filename newContent lastSaved
                        , WriteOut ( filename, newContent ) :: effects
                        )
            in
            ( Model { model | lastSaved = newLastSaved }
            , ( cmd
              , writeEffects
              )
            )

        decoders =
            [ config.files ]
                |> List.map (\(File filename (JsonMapping _ decode)) -> ( filename, decode ))
                |> Dict.fromList
    in
    { init =
        \() ->
            let
                ( model, cmd ) =
                    config.init
            in
            ( Model
                { appModel = model
                , lastSaved = Dict.empty
                }
            , ( cmd
              , [ config.files ]
                    |> List.map (\(File name _) -> name)
                    |> List.map LoadFile
              )
            )
    , update =
        \msg (Model model) ->
            let
                ( newModel, cmd ) =
                    config.update msg model.appModel
            in
            Model { model | appModel = newModel }
                |> saveFiles cmd
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
        \(Model model) ->
            Sub.batch
                [ config.subscriptions model.appModel
                , Ports.fileLoaded handleLoad
                ]
    , view =
        \(Model model) ->
            { title = ""
            , body =
                [ config.view model.appModel
                ]
            }
    }


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


jsonFile : String -> (b -> msg) -> JsonMapping b a -> File a msg
jsonFile filename toMsg (JsonMapping encode decode) =
    File filename (JsonMapping encode (Json.Decode.map toMsg decode))


type JsonMapping a b
    = JsonMapping (List ( String, b -> Json.Value )) (Decoder a)


jsonMapping : a -> JsonMapping a b
jsonMapping a =
    JsonMapping [] (Json.Decode.succeed a)


with : String -> (x -> a) -> (a -> Json.Value) -> Decoder a -> JsonMapping (a -> b) x -> JsonMapping b x
with name get toJson fd (JsonMapping fields decoder) =
    JsonMapping (( name, get >> toJson ) :: fields) (Json.Decode.map2 (\a f -> f a) (Json.Decode.field name fd) decoder)


withInt : String -> (x -> Int) -> JsonMapping (Int -> b) x -> JsonMapping b x
withInt name get =
    with name get Json.int Json.Decode.int


staticString : String -> String -> JsonMapping a x -> JsonMapping a x
staticString name value (JsonMapping fields decoder) =
    JsonMapping (( name, \_ -> Json.string value ) :: fields) decoder
